//
//  MixedImmersiveView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct MixedImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @Environment(CollectionStore.self) var collectionStore
    @Environment(MemoStore.self) var memoStore
    @Environment(TimelineStore.self) var timelineStore
    @Environment(PlacedImageStore.self) var placedImageStore
    @Environment(MiniMapManager.self) var miniMapManager
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    static let arSession = ARKitSession()
    static let worldTracking = WorldTrackingProvider()
    
    @State var root: Entity? = nil
    
    @State var anchorToMemo: [UUID: UUID] = [:]
    @State var pendingItemType: [UUID: UserControlItem] = [:]
    
    @State var photoGroup: Entity?
    @State var memoGroup: Entity?
    @State var teleportGroup: Entity?
    @State var timelineGroup: Entity?
    @State var placedImageGroup: Entity?
    
    @State var anchorRegistry = AnchorRegistry()
    @State var placementManager: PlacementManager? = nil
    
    // JSON 저장/복원 담당
    @State var persistence: PersistenceManager? = nil
    @State var bootstrap: SceneBootstrap? = nil
    
    @State var anchorSystem: AnchorSystem? = nil
    
    @State var inputSurface = SwiftUIInputSurface()
    @State var router: InteractionRouter? = nil
    @State var gestureBridge: GestureBridge? = nil
    
    @State var controller: MixedImmersiveController? = nil

    @State var isARSessionRunning = false
    
    var body: some View {
        RealityView { content in
            // 1) ARSession
            await startARSessionIFNeeded()
            
            // 2) 씬(root+groups) 준비
            await setupScene(content: content)
            
            openWindow(id: appModel.userControlWindowID)
            
            // 3) 의존성 준비
            setupDependenciesIfNeeded()
            
            // 4) restore
            if let bootstrap {
                await bootstrap.restoreAndSpawn()
            }
            
            if let controller {
                await controller.spawnTeleportGridIfNeeded(spacing: 1.5)
            }
            
            // 5) AnchorSystem은 단 1회 생성/시작
            setupAnchorSystemIfNeeded()
            if let root, let anchorSystem {
                try? await anchorSystem.attachRootAnchor(to: root)
            }
            anchorSystem?.start()
            
            // 6) Interaction pipeline 시작
            startInteractionPipelineIfReady()
        }
        .onChange(of: appModel.itemAdd, initial: false) { (oldValue: UserControlItem?, newValue: UserControlItem?) in
            guard let newValue else { return }
            commitItem(itemAdd: newValue)
        }
        .onChange(of: appModel.customHeight, initial: false) {(oldValue: Float, newValue: Float) in
            Task {
                await controller?.applyHeightAdjustment(customHeight: newValue)
            }
        }
        .onChange(of: appModel.visibleKinds, initial: true) { _, newValue in
            controller?.refreshScene(
                showPhotos: newValue.contains(.photo),
                showMemos: newValue.contains(.memo),
                showTimelines: newValue.contains(.timeline),
                showPlacedImage: newValue.contains(.placedImage),
                isTeleportVisible: newValue.contains(.teleport)
            )
        }
        .simultaneousGesture(tapEntityGesture)
        .simultaneousGesture(longPressEntityGesture)
        .simultaneousGesture(dragEntityGesture)

        .onAppear {
            // TODO: (지지) 리팩토링 필요!!!
            // timeline 앵커 삭제
            timelineStore.onTimelineDeleted = { timelineID in
                Task {
                    if let anchorID = anchorRegistry.records.values.first(
                        where: {
                            $0.kind == EntityKind.timeline.rawValue
                            && $0.dataRef == timelineID
                        })?.id
                    {
                        // 월드 앵커 삭제 로직 제거
                        // await removeWorldAnchor(by: anchorID)
                        // scene-local 를 삭제하는 함수 추후 추가
                        // ex) await controller?.removeSceneLocalAnchor(anchorID)
                    } else {
                        print(
                            "Timeline 삭제 알림 받았으나 연결된 앵커를 찾지 못함 for \(timelineID)"
                        )
                    }
                }
            }
            
            appModel.onTimelineShow = { timelineID in  // TimelineID
                // AnchorRegistry에서 해당 timelineDataID와 연결된 AnchorRecord를 찾기
                if let anchorRecord =
                    anchorRegistry
                    .all()
                    .first(where: {
                        $0.kind == EntityKind.timeline.rawValue
                        && $0.dataRef == timelineID
                    })
                {
                    let anchorID = anchorRecord.id  // 찾은 World Anchor의 UUID
                    
                    Task {
                        await controller?.teleportToID(to: anchorID, animated: true)
                    }
                } else {
                    print("텔레포트 대상 앵커를 찾을 수 없음: \(timelineID)")
                }
            }
            
            appModel.onTimelineHighlight = { timelineID in
                Task {
                    await controller?.highlightTimeline(timelineID: timelineID)
                }
            }
        }
        .onDisappear {
            anchorSystem?.stop()
        }
    }
    
    private func updateRealityContent(_ content: RealityViewContent) {
        controller?.refreshScene(
            showPhotos: appModel.showPhotos,
            showMemos: appModel.showMemos,
            showTimelines: appModel.showTimelines,
            showPlacedImage: appModel.showPlacedImages,
            isTeleportVisible: appModel.isTeleportVisible
        )
    }

    private func commitItem(itemAdd: UserControlItem) {
        switch itemAdd {
        case .photoCollection, .teleport:
            Task {
                await controller?.makePlacement(type: itemAdd)
                await MainActor.run {
                    appModel.itemAdd = nil
                }
            }
            
        case .memo:
            guard let memoID = memoStore.memoToAnchorID else { return }
            Task {
                if let existing =
                    anchorRegistry
                    .all()
                    .first(where: {
                        $0.kind == EntityKind.memo.rawValue
                        && $0.dataRef == memoID
                    })
                {
                    await controller?.refreshMemoOverlay(
                        anchorID: existing.id,
                        memoID: memoID
                    )
                } else {
                    await controller?.makePlacement(type: .memo)
                }
                await MainActor.run {
                    appModel.itemAdd = nil
                    memoStore.memoToAnchorID = nil
                }
            }
            
        case .timeline:
            guard let timelineID = appModel.timelineToAnchorID else { return }
            Task {
                if let existing =
                    anchorRegistry
                    .all()
                    .first(where: {
                        $0.kind == EntityKind.timeline.rawValue
                        && $0.dataRef == timelineID
                    })
                {
                    print("Timeline anchor already exists: \(existing.id)")
                } else {
                    await controller?.makePlacement(
                        type: .timeline,
                        dataRef: timelineID
                    )
                }
                await MainActor.run {
                    appModel.itemAdd = nil
                    appModel.timelineToAnchorID = nil
                }
            }
            
        case .placedImage:
            guard let placedImageID = placedImageStore.placedImageToAnchorID else { return }
            Task {
                if let existing = anchorRegistry
                    .all()
                    .first(where: { $0.kind == EntityKind.placedImage.rawValue && $0.dataRef == placedImageID })
                {
                    print("Placed Image anchor already exists: \(existing.id)")
                } else {
                    await controller?.makePlacement(type: .placedImage)
                }
                await MainActor.run {
                    appModel.itemAdd = nil
                    placedImageStore.placedImageToAnchorID = nil
                }
            }
        default :
            Task {
                await MainActor.run {
                    appModel.itemAdd = nil
                }
            }
        }
    }
}
