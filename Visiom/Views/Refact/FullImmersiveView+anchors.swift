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
        // 임시로 저장된 데이터 가져오기
        guard var data = anchorManager.getAnchor(id: anchor.id) else { return }
        
        let subjectClone: ModelEntity
        
        if data.itemType == .photo {
            subjectClone = AREntityFactory.createPhotoButton()
            photoGroup?.addChild(subjectClone) ?? root?.addChild(subjectClone)
        } else {
            subjectClone = AREntityFactory.createMemoBox()
            memoGroup?.addChild(subjectClone) ?? root?.addChild(subjectClone)
            
            // 메모 텍스트 추가
            if !data.memoText.isEmpty {
                let textOverlay = AREntityFactory.createMemoTextOverlay(text: data.memoText)
                textOverlay.setPosition(
                    [0, 0, ARConstants.Position.memoTextZOffset],
                    relativeTo: subjectClone
                )
                subjectClone.addChild(textOverlay)
            }
        }
        
        subjectClone.name = anchor.id.uuidString
        subjectClone.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
        
        data.entity = subjectClone
        anchorManager.anchorDataMap[anchor.id] = data
    }
    
    /// 앵커 업데이트 처리
    func handleAnchorUpdated(_ anchor: WorldAnchor) throws {
        try anchorManager.updateAnchor(id: anchor.id, anchor: anchor)
        
        if let data = anchorManager.getAnchor(id: anchor.id) {
            data.entity.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
            anchorManager.anchorDataMap[anchor.id] = data
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
        do {
            if let anchorToRemove = worldAnchorEntityData[id]?.anchor {
                try await Self.worldTracking.removeAnchor(anchorToRemove)
                print("remove anchor: \(id)")
            } else {
                print("cannot find")
            }
        } catch {
            print("error: \(error)")
        }
    }
}
