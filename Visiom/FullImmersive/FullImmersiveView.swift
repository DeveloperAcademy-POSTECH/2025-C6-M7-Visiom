//
//  FullImmersiveView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct FullImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @Environment(CollectionStore.self) var collectionStore
    @Environment(EntityManager.self) private var entityManager
    @Environment(MemoStore.self) var memoStore
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    static let arSession = ARKitSession()
    static let worldTracking = WorldTrackingProvider()
    
    // teleport
    @State var root: Entity? = nil
    @State var sceneContent: Entity?

    @State var anchorToMemo: [UUID: UUID] = [:]
    @State var pendingItemType: [UUID: UserControlItem] = [:]

    @State var photoGroup: Entity?
    @State var memoGroup: Entity?
    @State var teleportGroup: Entity?
    
    @State var anchorRegistry = AnchorRegistry()
    @State var placementManager: PlacementManager? = nil
    @State var entityByAnchorID: [UUID: Entity] = [:]
    
    // JSON 저장/복원 담당
    @State var persistence: PersistenceManager? = nil
    @State var bootstrap: SceneBootstrap? = nil
    
    @State var anchorSystem: AnchorSystem? = nil
    
    @State private var inputSurface = SwiftUIInputSurface()
    @State private var router: InteractionRouter? = nil
    @State private var gestureBridge: GestureBridge? = nil
    
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
        .onChange(of: appModel.itemAdd) { newValue in
            if newValue == .photoCollection {
                Task { await makePlacement(type: .photoCollection) }
                appModel.itemAdd = nil
            }
        }
        .onChange(of: appModel.memoToAnchorID) { memoID in
            guard let memoID else { return }
            Task {
                if let existing = anchorRegistry
                    .all()
                    .first(where: { $0.kind == EntityKind.memo.rawValue && $0.dataRef == memoID })
                {
                    await refreshMemoOverlay(anchorID: existing.id, memoID: memoID)
                } else {
                    await makePlacement(type: .memo)
                }
                await MainActor.run { appModel.memoToAnchorID = nil }
            }
        }
        .onChange(of: appModel.itemAdd) { newValue in
            if newValue == .teleport {
                Task { await makePlacement(type: .teleport) }
                appModel.itemAdd = nil
            }
        }
        /// visible/invisible 처리 부분
        /// 다른 방법이 있는지 찾아보기
        .onChange(of: appModel.showPhotos) { newValue in
            photoGroup?.isEnabled = newValue
        }
        .onChange(of: appModel.showMemos) { newValue in
            memoGroup?.isEnabled = newValue
        }
        .simultaneousGesture(tapEntityGesture)
        .simultaneousGesture(longPressEntityGesture)
        .simultaneousGesture(dragEntityGesture)
        
        /// AR 세션 관리
        .task {
            await FullImmersiveView.startARSession()
        }
        .onDisappear {
            anchorSystem?.stop()
        }
    }
    
    private func updateRealityContent(_ content: RealityViewContent) {
        refreshScene()
    }
    
    private func refreshScene() {
        /// 역할: entity 계층 구조 점검하기
        /// entity new! 설계 적용 후에는 정말 필요한게 맞는지 점검 필요
        updateEntityHierarchy()
        /// 역할: entity 계층에 따라 show/hide 설정하기
        /// 함수 내부 구조 변경 필요할 수도
        updateGroupVisibility()
    }
    
    private func buildRealityContent(_ content: RealityViewContent) async {
        await setupScene(content: content)
        await MainActor.run { startInteractionPipelineIfReady() }
    }
    
    @MainActor
    func startInteractionPipelineIfReady() {
        guard router == nil, gestureBridge == nil else { return }
        guard let pm = placementManager, let ps = persistence else { return }
        
        let openRoute: (String) -> Void = { route in
            appModel.open(routeString: route, openWindow: openWindow)
        }
        let dismissRoute: (String) -> Void = { route in
            appModel.dismiss(routeString: route, dismissWindow: dismissWindow)
        }
        
        let ctx = InteractionContext(
            placement: pm,
            persistence: ps,
            openWindow: openRoute,
            dismissWindow: dismissRoute
        )
        router = InteractionRouter(context: ctx)
        gestureBridge = GestureBridge(surface: inputSurface, router: router!)
        
        if pm.onMoved == nil {
            placementManager?.onMoved = { [self] rec in
                if let e = self.entityByAnchorID[rec.id] {
                    e.setTransformMatrix(rec.worldMatrix, relativeTo: nil)
                }
            }
        }
        if pm.onRemoved == nil {
            placementManager?.onRemoved = { [self] anchorID in
                if let e = self.entityByAnchorID.removeValue(forKey: anchorID) {
                    e.removeFromParent()
                }
                self.anchorRegistry.remove(anchorID)
                self.persistence?.save()
            }
        }
    }
    
    // MARK: - Gestures (분리)
    private var tapEntityGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                inputSurface.setLastHitEntity(value.entity)
                let p = value.entity.position(relativeTo: nil)
                let wp = SIMD3<Float>(p.x, p.y, p.z)
                inputSurface.onTap?(.zero, wp)
            }
    }
    
    private var longPressEntityGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.75)
            .targetedToAnyEntity()
            .onEnded { value in
                inputSurface.setLastHitEntity(value.entity)
                inputSurface.onLongPress?(.zero)
            }
    }
    
    private var dragEntityGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                inputSurface.setLastHitEntity(value.entity)
                let pNow = value.convert(value.location3D, from: .local, to: value.entity.parent!)
                let world = SIMD3<Float>(pNow.x, pNow.y, pNow.z)
                inputSurface.pushDragSample(currentWorld: world, isEnded: false)
            }
            .onEnded { _ in
                inputSurface.pushDragSample(currentWorld: nil, isEnded: true)
            }
    }
    
    // Ext+FullImmersiveView.swift (동일 파일 내부)
    @MainActor
    private func refreshMemoOverlay(anchorID: UUID, memoID: UUID) async {
        guard let container = entityByAnchorID[anchorID] else { return }

        // 1) 기존 텍스트 오버레이 제거 (ViewAttachmentEntity만 골라서 제거)
        for child in container.children {
            if child is ViewAttachmentEntity { child.removeFromParent() }
        }

        // 2) 최신 텍스트로 새 오버레이 부착
        if let text = memoStore.memo(id: memoID)?.text, !text.isEmpty {
            let overlay = AREntityFactory.createMemoTextOverlay(text: text)
            container.addChild(overlay)
            overlay.setPosition([0, 0, ARConstants.Position.memoTextZOffset],
                                relativeTo: container)
        }
    }
}
