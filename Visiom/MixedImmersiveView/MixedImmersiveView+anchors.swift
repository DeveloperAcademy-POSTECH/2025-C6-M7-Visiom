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

// MARK: - Anchor 관리 Extension
extension MixedImmersiveView {
    
    func setupPersistenceIfNeeded() {
        if persistence == nil {
            persistence = PersistenceManager(anchorRegistry: anchorRegistry)
        }
    }
    
    func setupAnchorSystem() {
        anchorSystem = AnchorSystem(
            worldTracking: Self.worldTracking,
            anchorRegistry: anchorRegistry,
            persistence: persistence,
            entityForAnchorID: { id in entityByAnchorID[id] },
            setEntityForAnchorID: { id, e in entityByAnchorID[id] = e },
            spawnEntity: { rec in await spawnEntity(rec) }
        )
        
        // 레코드가 없는 앵커가 추가된 경우(메모/임시 대기열 처리)
        anchorSystem?.onAnchorAddedWithoutRecord = { anchor in
            // 기존 handleAnchorAdded의 memo/pending 처리를 이곳으로 이동
            if let memoId = anchorToMemo.removeValue(forKey: anchor.id) {
                await handleMemoAnchorAdded(anchor, memoID: memoId)
                return
            }
            _ = pendingItemType.removeValue(forKey: anchor.id)
        }
        
        // 제거 시 보조 맵 정리
        anchorSystem?.onAnchorRemoved = { id in
            anchorToMemo.removeValue(forKey: id)
            pendingItemType.removeValue(forKey: id)
        }
    }
    
    private func handleMemoAnchorAdded(_ anchor: WorldAnchor, memoID: UUID) async {
        let memoText = memoStore.memo(id: memoID)?.text ?? ""
        
        
        let entity =  AREntityFactory.createMemoBox()
        (memoGroup ?? root)?.addChild(entity)
        
        // 텍스트 오버레이 추가 (내용이 있을 때만)
        if !memoText.isEmpty {
            let textOverlay = AREntityFactory.createMemoTextOverlay(text: memoText)
            
            entity.addChild(textOverlay)
            
            textOverlay.setPosition(
                [0, 0, ARConstants.Position.memoTextZOffset],
                relativeTo: entity
            )
        }
        
        entity.name = anchor.id.uuidString
        entity.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
        
        // 레코드가 없던 상황이므로 최소 레코드 생성 후 upsert
        let rec = AnchorRecord(
            id: anchor.id,
            kind: EntityKind.memo.rawValue,
            dataRef: memoID,
            transform: anchor.originFromAnchorTransform
        )
        anchorRegistry.upsert(rec)
        
        // 스폰 맵 업데이트
        entityByAnchorID[anchor.id] = entity
        
        // 저장
        persistence?.save()
        print("persistence?.save() 호출 : AnchorSystem.handleMemoAnchorAdded")
        
    }
    
    /// 월드 앵커 제거
    func removeWorldAnchor(by id: UUID) async {
        anchorRegistry.remove(id)
        if let e = entityByAnchorID.removeValue(forKey: id) { e.removeFromParent() }
        persistence?.save()
        print("persistence?.save() 호출 : AnchorSystem.removeWorldAnchor")
    }
}
