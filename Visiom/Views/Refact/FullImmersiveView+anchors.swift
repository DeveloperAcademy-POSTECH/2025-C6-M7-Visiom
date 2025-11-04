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
                    await handleAnchorAdded(update.anchor)
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
    func handleAnchorAdded(_ anchor: WorldAnchor) async {
        
        if let colId = anchorToCollection.removeValue(forKey: anchor.id) {
            await handlePhotoAnchorAdded(anchor, collectionID: colId)
            return
        }
        
        if let memoId = anchorToMemo.removeValue(forKey: anchor.id) {
            await handleMemoAnchorAdded(anchor, memoID: memoId)
            return
        }
        
        guard let itemType = pendingItemType.removeValue(forKey: anchor.id) else { return }
        
        switch itemType {
        case .sticker:
            await handleStickerAnchorAdded(anchor)
        case .number:
            await handleNumberAnchorAdded(anchor)
        case .mannequin:
            await handleMannequinAnchorAdded(anchor)
            
            // 이미 메모/포토는 위에서 리턴됨
        case .memo, .photo:
            print("ℹ️ handleAnchorAdded: \(itemType) is handled via explicit maps.")
        default:
            print("nothing")
        }
    }
    
    private func handlePhotoAnchorAdded(_ anchor: WorldAnchor, collectionID: UUID?) async {
        do {
            let entity = try await AREntityFactory.createPhotoButton()
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
        } catch {
            print("⚠️ handlePhotoAnchorAdded failed: \(error)")
        }
    }
    
    private func handleMemoAnchorAdded(_ anchor: WorldAnchor, memoID: UUID) async {
        let memoText = memoStore.memo(id: memoID)?.text ?? ""
        
        do {
            let entity = try await AREntityFactory.createMemoBox()
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
        } catch {
            print("⚠️ handleMemoAnchorAdded failed: \(error)")
        }
    }
    
    // 스티커
    private func handleStickerAnchorAdded(_ anchor: WorldAnchor) async { // 수정: async
        guard let parent = root else { return }
        do {
            let e = try await AREntityFactory.createBooldSticker() // 수정: try await
            parent.addChild(e)
            e.name = anchor.id.uuidString
            e.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
            
            let data = AnchorData(
                id: anchor.id, anchor: anchor, entity: e,
                itemType: .sticker, memoText: "", collectionID: UUID?(nil) // 수정: 명시
            )
            anchorManager.addAnchor(data)
        } catch {
            print("⚠️ handleStickerAnchorAdded failed: \(error)")
        }
    }

    // 넘버
    private func handleNumberAnchorAdded(_ anchor: WorldAnchor) async { // 수정: async
        guard let parent = root else { return }
        numberPickerCount += 1
        let label = "\(numberPickerCount)"
        
        // 수정: createNumberPlate 대체 – 얇은 상자(plate) 직접 생성
        let plate: ModelEntity = {
            let w: Float = 0.18, h: Float = 0.18, d: Float = 0.01
            let m = SimpleMaterial(color: .white.withAlphaComponent(0.9), isMetallic: false)
            let e = ModelEntity(mesh: .generateBox(width: w, height: h, depth: d), materials: [m])
            e.components.set(CollisionComponent(shapes: [.generateBox(width: w, height: h, depth: d)]))
            e.components.set(InputTargetComponent())
            return e
        }() // 수정
        
        parent.addChild(plate)
        
        let overlay = AREntityFactory.createMemoTextOverlay(text: label)
        plate.addChild(overlay)
        overlay.setPosition([0, 0, max(ARConstants.Position.memoTextZOffset, 0.01)], relativeTo: plate)
        overlay.components.set(BillboardComponent())
        
        plate.name = anchor.id.uuidString
        plate.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
        
        let data = AnchorData(
            id: anchor.id, anchor: anchor, entity: plate,
            itemType: .number, memoText: label, collectionID: UUID?(nil) // 수정: 명시
        )
        anchorManager.addAnchor(data)
    }

    // 마네킹
    private func handleMannequinAnchorAdded(_ anchor: WorldAnchor) async { // 수정: async
        guard let parent = root else { return }
        do {
            let mannequin = try await AREntityFactory.createBody() // 수정: try await
            parent.addChild(mannequin)
            mannequin.name = anchor.id.uuidString
            mannequin.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
            
            let data = AnchorData(
                id: anchor.id, anchor: anchor, entity: mannequin,
                itemType: .mannequin, memoText: "", collectionID: UUID?(nil) // 수정: 명시
            )
            anchorManager.addAnchor(data)
        } catch {
            print("⚠️ handleMannequinAnchorAdded failed: \(error)")
        }
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
