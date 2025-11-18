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
    
    /// AR 세션 시작
    static func startARSession() async {
        guard WorldTrackingProvider.isSupported else {
            print("error: 월드 트래킹이 안됨")
            return
        }
        
        do {
            try await arSession.run([/*handTracking, */worldTracking])
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
            return
        }
        
        // 씬 로드
        guard let immersiveContentEntity = try? await Entity(
            named: "ChrimeScene",
            in: realityKitContentBundle
        ) else {
            print("❌ Failed to load Immersive content")
            return
        }
        immersiveContentEntity.name = "MainChrimeScene"
        immersiveContentEntity.generateCollisionShapes(recursive: true)
        root = immersiveContentEntity
        content.add(immersiveContentEntity)
        
        // 어디에서도 사용하지 않음
        // 추후 삭제 예정
//        if let sceneContent = root!.findEntity(named: "Root") {
//            self.sceneContent = sceneContent
//        }
        
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
        
        // MARK: - Anchor / Persistence / Bootstrap 세팅
        
        let placementManager = PlacementManager(
            anchorRegistry: anchorRegistry,
            sceneRoot: immersiveContentEntity
        )
        self.placementManager = placementManager
        
        let persistence = PersistenceManager(anchorRegistry: anchorRegistry)
        self.persistence = persistence
        
        let bootstrap = SceneBootstrap(
            sceneRoot: immersiveContentEntity,
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
        controller.root = immersiveContentEntity
        controller.photoGroup = pGroup
        controller.memoGroup = mGroup
        controller.teleportGroup = tGroup
        self.controller = controller
        
        // MARK: - Bootstrap 콜백 → 컨트롤러와 연동
        
        bootstrap.onSpawned = { [weak controller] id, entity in
            guard let controller else { return }
            controller.entityByAnchorID[id] = entity
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent())
        }
        
        bootstrap.memoTextProvider = { [weak memoStore] memoID in
            memoStore?.memo(id: memoID)?.text
        }
        
        // 디스크에서 앵커 복원 & 엔티티 스폰
        await bootstrap.restoreAndSpawn()
    }
}
