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
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    static let arSession = ARKitSession()
    static let worldTracking = WorldTrackingProvider()
    
    @State var root: Entity? = nil
    //@State var sceneContent: Entity?
    
    @State var anchorToMemo: [UUID: UUID] = [:]
    @State var pendingItemType: [UUID: UserControlItem] = [:]
    
    @State var photoGroup: Entity?
    @State var memoGroup: Entity?
    @State var teleportGroup: Entity?
    
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
            updateRealityContent(content)
        }
        .onChange(of: appModel.itemAdd, initial: false) {_, newValue in
            guard let newValue else { return }
            Task {
                await controller?.makePlacement(type: newValue)
                await MainActor.run {
                    appModel.itemAdd = nil
                }
            }
        }

        .onChange(of: memoStore.memoToAnchorID, initial: false) {_, memoID in
            guard let memoID else { return }
            Task {
                if let existing = anchorRegistry
                    .all()
                    .first(where: { $0.kind == EntityKind.memo.rawValue && $0.dataRef == memoID })
                {
                    await controller?.refreshMemoOverlay(anchorID: existing.id, memoID: memoID)
                } else {
                    await controller?.makePlacement(type: .memo)
                }
                await MainActor.run { memoStore.memoToAnchorID = nil }
            }
        }
        .simultaneousGesture(tapEntityGesture)
        .simultaneousGesture(longPressEntityGesture)
        .simultaneousGesture(dragEntityGesture)
        
        /// AR 세션 관리
        .task {
            await MixedImmersiveView.startARSession()
        }
        .onDisappear {
            anchorSystem?.stop()
        }
    }
    
    private func updateRealityContent(_ content: RealityViewContent) {
        controller?.refreshScene(
            showPhotos: appModel.showPhotos,
            showMemos: appModel.showMemos,
            showTeleports: appModel.showTeleports
        )
    }
    
    private func buildRealityContent(_ content: RealityViewContent) async {
        await setupScene(content: content)
        await MainActor.run { startInteractionPipelineIfReady() }
    }
}
