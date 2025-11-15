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

    /// 씬 초기 설정 - root 엔티티 및 그룹 생성
    @MainActor
    func setupScene(content: RealityViewContent) async {

        
        // 이미 로드된 경우 중복 추가 방지
        guard root == nil else {
            if let existingRoot = root {
                content.add(existingRoot)
            }
            return
        }
        
        // 씬 갈아끼기
        if let immersiveContentEntity = try? await Entity(
            named: "Immersive",
            in: realityKitContentBundle
        ) {
            immersiveContentEntity.generateCollisionShapes(recursive: true)
            root = immersiveContentEntity
            content.add(root!)
            
            if let sceneContent = root!.findEntity(named: "Root") {
                self.sceneContent = sceneContent
            }
            
            // Photo 그룹 생성
            let pGroup = Entity()
            pGroup.name = "PhotoGroup"
            pGroup.isEnabled = appModel.showPhotos
            root?.addChild(pGroup)
            self.photoGroup = pGroup
            
            // Memo 그룹 생성
            let mGroup = Entity()
            mGroup.name = "MemoGroup"
            mGroup.isEnabled = appModel.showMemos
            root?.addChild(mGroup)
            self.memoGroup = mGroup
            
            self.placementManager = PlacementManager(anchorRegistry: anchorRegistry, sceneRoot: immersiveContentEntity)
            
            let p = PersistenceManager(anchorRegistry: anchorRegistry)
            self.persistence = p
            
            
            let b = SceneBootstrap(sceneRoot: immersiveContentEntity, anchorRegistry: anchorRegistry, persistence: p)
            self.bootstrap = b
            
            b.onSpawned = { [self] id, entity in
                entityByAnchorID[id] = entity
                entity.generateCollisionShapes(recursive: false)
                entity.components.set(InputTargetComponent())
            }
            
            b.memoTextProvider = { [self] memoID in
                memoStore.memo(id:memoID)?.text
            }
            
            await b.restoreAndSpawn()
        }
    }
}
