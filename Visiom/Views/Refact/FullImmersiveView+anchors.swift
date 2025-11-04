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
        // 임시로 저장된 데이터 가져오기
        //        guard var data = anchorManager.getAnchor(id: anchor.id) else { return }

        guard let itemType = pendingItemType.removeValue(forKey: anchor.id)
        else {
            print(
                "⚠️ handleAnchorAdded: No pending itemType hint found for anchor \(anchor.id). Ignoring."
            )
            return
        }

        var collectionID: UUID? = nil
        var memo: String = ""

        switch itemType {
        case .photo:
            collectionID = anchorToCollection.removeValue(forKey: anchor.id)
            if collectionID == nil {
                print(
                    "handleAnchorAdded: Photo itemType hint found, but no matching collectionID in anchorToCollection."
                )
            }
        case .memo:
            memo = memoText.removeValue(forKey: anchor.id) ?? ""
        default:
            break
        }

        let subjectClone: ModelEntity

        switch itemType {
        case .photo:
            subjectClone = AREntityFactory.createPhotoButton()
            photoGroup?.addChild(subjectClone) ?? root?.addChild(subjectClone)
        case .memo:
            subjectClone = AREntityFactory.createMemoBox()
            memoGroup?.addChild(subjectClone) ?? root?.addChild(subjectClone)

            // 메모 텍스트 추가
            if !memo.isEmpty {
                let textOverlay = AREntityFactory.createMemoTextOverlay(
                    text: memo
                )
                textOverlay.setPosition(
                    [0, 0, ARConstants.Position.memoTextZOffset],
                    relativeTo: subjectClone
                )
                subjectClone.addChild(textOverlay)
            }

        case .sticker:
            do {
                subjectClone = try await AREntityFactory.createBooldSticker()
                root?.addChild(subjectClone)
            } catch {
                print("Failed to create photo sticker entity: \(error)")
                return
            }
        default:
            print("default: Unhandled itemType. Returning.")
            return
        }

        subjectClone.name = anchor.id.uuidString
        subjectClone.setTransformMatrix(
            anchor.originFromAnchorTransform,
            relativeTo: nil
        )

        let newData = AnchorData(
            id: anchor.id,
            anchor: anchor,
            entity: subjectClone,
            itemType: itemType,
            memoText: memo,
            collectionID: collectionID
        )

        anchorManager.addAnchor(newData)
    }

    /// 앵커 업데이트 처리
    func handleAnchorUpdated(_ anchor: WorldAnchor) throws {
        guard let data = anchorManager.getAnchor(id: anchor.id) else {
            print(
                "⚠️ Ignoring update for unknown anchor (race condition): \(anchor.id)"
            )
            return
        }
        try anchorManager.updateAnchor(id: anchor.id, anchor: anchor)

        data.entity.setTransformMatrix(
            anchor.originFromAnchorTransform,
            relativeTo: nil
        )
        anchorManager.anchorDataMap[anchor.id] = data

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
