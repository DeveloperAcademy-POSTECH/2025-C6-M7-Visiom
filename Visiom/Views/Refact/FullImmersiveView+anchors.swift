//
//  Ext+FullImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

// MARK: - Anchor 관리 Extension
extension FullImmersiveView {
    
    /// 앵커 업데이트 모니터링
    func observeAnchorUpdates() async {
        do {
            for await update in Self.worldTracking.anchorUpdates {
                switch update.event {
                case .added:
                    handleAnchorAdded(update.anchor)
                case .updated:
                    do {
                        try handleAnchorUpdated(update.anchor)
                    } catch {
                        print("⚠️ Failed to handle anchor updated: \(error)")
                    }
                case .removed:
                    handleAnchorRemoved(update.anchor.id)
                }
            }
        }
    }
    
    /// 앵커 추가 처리
    func handleAnchorAdded(_ anchor: WorldAnchor) {
        
        if let colId = anchorToCollection.removeValue(forKey: anchor.id) {
            handlePhotoAnchorAdded(anchor, collectionID: colId)
            return
        }
        
        if let memoId = anchorToMemo.removeValue(forKey: anchor.id) {
            handleMemoAnchorAdded(anchor, memoID: memoId)
            return
        }
    }
    
    private func handlePhotoAnchorAdded(_ anchor: WorldAnchor, collectionID: UUID?) {
        let entity = AREntityFactory.createPhotoButton()
        (photoGroup ?? root)?.addChild(entity)
        
        entity.name = anchor.id.uuidString
        entity.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
        
        let data = AnchorData(
            id: anchor.id,
            anchor: anchor,
            entity: entity,
            itemType: .photo,
            memoText: "",
            collectionID: collectionID
        )
        
        anchorManager.addAnchor(data)
    }
    
    private func handleMemoAnchorAdded(_ anchor: WorldAnchor, memoID: UUID) {
        let memoText = memoStore.memo(id: memoID)?.text ?? ""
        
        let entity = AREntityFactory.createMemoBox()
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
        
        let data = AnchorData(
            id: anchor.id,
            anchor: anchor,
            entity: entity,
            itemType: .memo,
            memoText: memoText,
            collectionID: nil
        )
        
        anchorManager.addAnchor(data)
    }
    
    /// 앵커 업데이트 처리
    func handleAnchorUpdated(_ anchor: WorldAnchor) throws {
        guard let data = anchorManager.getAnchor(id: anchor.id) else {
            print(
                "⚠️ Ignoring update for unknown anchor (race condition): \(anchor.id)"
            )
            return
        }
        
        data.entity.setTransformMatrix(
            anchor.originFromAnchorTransform,
            relativeTo: nil
        )
        anchorManager.anchorDataMap[anchor.id] = data
        
        do {
            try anchorManager.updateAnchor(id: anchor.id, anchor: anchor)
        } catch {
            print("⚠️ Failed to update anchor:", error)
        }
        
    }
    
    /// 앵커 제거 처리
    func handleAnchorRemoved(_ id: UUID) {
        if let data = anchorManager.removeAnchor(id: id) {
            data.entity.removeFromParent()
        }
    }
    
    /// 월드 앵커 제거
    func removeWorldAnchor(by id: UUID) async {
        guard let anchorToRemove = anchorManager.getAnchor(id: id) else {
            return
        }
        do {
            try await Self.worldTracking.removeAnchor(anchorToRemove.anchor)
            print("remove anchor: \(id)")
            handleAnchorRemoved(id)
        } catch {
            print("error: \(error)")
        }
    }
}
