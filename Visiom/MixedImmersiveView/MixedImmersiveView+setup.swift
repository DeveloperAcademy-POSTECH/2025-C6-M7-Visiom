//
//  Ext+MixedImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

// MARK: - Setup Extension
extension MixedImmersiveView {
    
    func startARSessionIFNeeded() async {
        guard !isARSessionRunning else { return }
        isARSessionRunning = true
        await MixedImmersiveView.startARSession()
    }
    
    static func startARSession() async {
        guard WorldTrackingProvider.isSupported else {
            print("error: 월드 트래킹이 안됨")
            return
        }
        
        do {
            try await arSession.run([ /*handTracking, */worldTracking])
        } catch {
            print("AR session failed")
        }
    }
    
    /// 씬 초기 설정 - root 엔티티 및 그룹 생성 + 컨트롤러 생성
    @MainActor
    func setupScene(content: RealityViewContent) async {
        
        // 이미 로드된 경우 중복 추가 방지
        if let existingRoot = root {
            content.add(existingRoot)
            if photoGroup == nil || memoGroup == nil || teleportGroup == nil || timelineGroup == nil {
                reconnectGroupsIfNeeded()
            }
            return
        }
        
        let fileName = appModel.selectedSceneFileName
        
        // 씬 로드
        guard
            let immersiveContentEntity = try? await Entity(
                named: fileName,
                in: realityKitContentBundle
            )
        else {
            print("❌ Failed to load Immersive content: \(fileName)")
            return
        }
        immersiveContentEntity.name = "Immersive"
        immersiveContentEntity.generateCollisionShapes(recursive: true)
        root = immersiveContentEntity
        content.add(immersiveContentEntity)
        
        // MARK: - 그룹 생성
        
        // Photo 그룹
        let pGroup = Entity()
        pGroup.name = "PhotoGroup"
        pGroup.isEnabled = appModel.showPhotos
        immersiveContentEntity.addChild(pGroup)
        self.photoGroup = pGroup
        
        // Memo 그룹
        let mGroup = Entity()
        mGroup.name = "MemoGroup"
        mGroup.isEnabled = appModel.showMemos
        immersiveContentEntity.addChild(mGroup)
        self.memoGroup = mGroup
        
        // Teleport 그룹 (없었다면 추가)
        let tGroup = Entity()
        tGroup.name = "TeleportGroup"
        tGroup.isEnabled = appModel.showTeleports
        immersiveContentEntity.addChild(tGroup)
        self.teleportGroup = tGroup
        
        let timeGroup = Entity()
        timeGroup.name = "TimelineGroup"
        timeGroup.isEnabled = appModel.showTimelines
        root?.addChild(timeGroup)
        self.timelineGroup = timeGroup
        
        let pimageGroup = Entity()
        pimageGroup.name = "PlacedImageGroup"
        pimageGroup.isEnabled = appModel.showPlacedImages
        root?.addChild(pimageGroup)
        self.placedImageGroup = pimageGroup
    }
    
    func setupDependenciesIfNeeded() {
        // MARK: - Anchor / Persistence / Bootstrap 세팅
        guard placementManager == nil,
              persistence == nil,
              bootstrap == nil,
              controller == nil else { return }
        
        guard let sceneRoot = root else { return }
        
        if photoGroup == nil || memoGroup == nil || teleportGroup == nil || timelineGroup == nil || placedImageGroup == nil {
            reconnectGroupsIfNeeded()
        }
        
        let placementManager = PlacementManager(
            anchorRegistry: anchorRegistry,
            sceneRoot: sceneRoot
        )
        self.placementManager = placementManager
        
        let persistence = PersistenceManager(anchorRegistry: anchorRegistry)
        self.persistence = persistence
        
        let bootstrap = SceneBootstrap(
            sceneRoot: sceneRoot,
            anchorRegistry: anchorRegistry,
            persistence: persistence
        )
        self.bootstrap = bootstrap
        
        // MARK: - MixedImmersiveController 생성
        
        let controller = MixedImmersiveController(
            worldTracking: Self.worldTracking,
            anchorRegistry: anchorRegistry,
            persistence: persistence,
            bootstrap: bootstrap,
            placementManager: placementManager,
            memoStore: memoStore,
            collectionStore: collectionStore,
            placedImageStore: placedImageStore,
            windowIDPhotoCollection: appModel.photoCollectionWindowID,
            openWindow: { id, anyValue in
                // 컨트롤러에서는 Any? 로 받지만 실제로는 UUID를 넘길 예정
                if let uuid = anyValue as? UUID {
                    openWindow(id: id, value: uuid)
                } else {
                    openWindow(id: id, value: nil as UUID?)
                }
            }
        )
        
        // 컨트롤러에 씬 루트/그룹 연결
        controller.root = sceneRoot
        controller.photoGroup = photoGroup
        controller.memoGroup = memoGroup
        controller.teleportGroup = teleportGroup
        controller.timelineGroup = timelineGroup
        controller.placedImageGroup = placedImageGroup
        self.controller = controller
        
        // MARK: - Bootstrap 콜백 → 컨트롤러와 연동
        
        bootstrap.onSpawned = { [weak controller] id, entity in
            guard let controller else { return }
            controller.entityByAnchorID[id] = entity
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent())
            
            miniMapManager.updateAnchor(
                entityByAnchorID: controller.entityByAnchorID
            )
        }
        
        bootstrap.memoTextProvider = { [weak memoStore] memoID in
            memoStore?.memo(id: memoID)?.text
        }
        bootstrap.placedImageURLProvider = { [weak placedImageStore, weak collectionStore] placedImageID in
            guard
                let placed = placedImageStore?.placedImage(with: placedImageID),
                let collectionStore = collectionStore
            else { return nil }
            
            return collectionStore.photoURL(
                collectionID: placed.sourcePhotoCollectionID,
                fileName: placed.imageFileName
            )
        }
    }
    
    func setupAnchorSystemIfNeeded() {
        guard anchorSystem == nil else { return }
        guard let controller, let persistence else { return }
        
        anchorSystem = AnchorSystem(
            worldTracking: Self.worldTracking,
            anchorRegistry: anchorRegistry,
            persistence: persistence,
            entityForAnchorID: { [weak controller] id in
                controller?.entityByAnchorID[id]
            },
            setEntityForAnchorID: { [weak controller, weak miniMapManager] id, e in
                controller?.entityByAnchorID[id] = e
                miniMapManager?.updateAnchor(
                    entityByAnchorID: controller?.entityByAnchorID ?? [:]
                )
            },
            spawnEntity: { [weak controller, weak miniMapManager] rec in
                guard let controller else { return }
                await controller.spawnEntity(rec)
                miniMapManager?.updateAnchor(
                    entityByAnchorID: controller.entityByAnchorID
                )
            }
        )
    }
    
    @MainActor
    func startInteractionPipelineIfReady() {
        guard router == nil, gestureBridge == nil else { return }
        guard let placement = placementManager, let persistence = persistence else { return }
        
        let openRoute: (String) -> Void = { route in
            appModel.open(routeString: route, openWindow: openWindow)
        }
        let dismissRoute: (String) -> Void = { route in
            appModel.dismiss(routeString: route, dismissWindow: dismissWindow)
        }
        
        let ctx = InteractionContext(
            placement: placement,
            persistence: persistence,
            openWindow: openRoute,
            dismissWindow: dismissRoute,
            teleportToID: { id in
                Task { await controller?.teleportToID(to:id, animated:false) }
            }
        )
        router = InteractionRouter(context: ctx)
        gestureBridge = GestureBridge(surface: inputSurface, router: router!)
        
        placementManager?.onMoved = { [self] rec in
            guard let e = controller?.entityByAnchorID[rec.id],
                  let sceneRoot = controller?.sceneRoot else { return }
            e.setTransformMatrix(rec.worldMatrix, relativeTo: sceneRoot)
        }
        
        placementManager?.onRemoved = { [self] anchorID in
            if let e = controller?.entityByAnchorID.removeValue(forKey: anchorID) {
                e.removeFromParent()
            }
            self.anchorRegistry.remove(anchorID)
            self.persistence?.save()
        }
    }
    
    func reconnectGroupsIfNeeded() {
        if let root {
            photoGroup = photoGroup ?? root.findEntity(named: "PhotoGroup")
            memoGroup = memoGroup ?? root.findEntity(named: "MemoGroup")
            teleportGroup = teleportGroup ?? root.findEntity(named: "TeleportGroup")
            timelineGroup = timelineGroup ?? root.findEntity(named: "TimelineGroup")
            placedImageGroup = placedImageGroup ?? root.findEntity(named: "PlacedImageGroup")
        }
    }
}
