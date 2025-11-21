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

    var body: some View {
        RealityView { content in
            await buildRealityContent(content)

            setupPersistenceIfNeeded()
            setupAnchorSystem()
            anchorSystem?.start()
            startInteractionPipelineIfReady()
        } update: { content in
            miniMapManager.orientationChange90Degrees(content: content)
        }
        .onChange(of: appModel.itemAdd, initial: false) { _, newValue in
            guard let newValue else { return }
            Task {
                await controller?.makePlacement(type: newValue)
                await MainActor.run {
                    appModel.itemAdd = nil
                }
            }
        }
        .onChange(of: memoStore.memoToAnchorID, initial: false) { _, memoID in
            guard let memoID else { return }
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
                await MainActor.run { memoStore.memoToAnchorID = nil }
            }
        }

        .onChange(of: appModel.timelineToAnchorID, initial: false) {
            _,
            timelineID in
            guard let timelineID else { return }
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
                await MainActor.run { appModel.timelineToAnchorID = nil }
            }
        }
        .task(id: appModel.customHeight) {
            try? await Task.sleep(for: .milliseconds(100))

            await controller?.applyHeightAdjustment(
                customHeight: appModel.customHeight
            )
        }
        .simultaneousGesture(tapEntityGesture)
        .simultaneousGesture(longPressEntityGesture)
        .simultaneousGesture(dragEntityGesture)

        /// AR 세션 관리
        .task {
            await MixedImmersiveView.startARSession()
        }
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
                        await removeWorldAnchor(by: anchorID)
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
                        await controller?.smoothTeleport(anchorID: anchorID)
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
            showTeleports: appModel.showTeleports,
            showTimelines: appModel.showTimelines
        )
    }

    private func buildRealityContent(_ content: RealityViewContent) async {
        await setupScene(content: content)
        await MainActor.run { startInteractionPipelineIfReady() }
    }
}
