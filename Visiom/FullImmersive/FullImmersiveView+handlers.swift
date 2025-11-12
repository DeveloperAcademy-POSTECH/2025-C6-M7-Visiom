//
//  Ext+FullImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import SwiftUI

// MARK: - Handlers Extension
extension FullImmersiveView {
//
//    var teleportDragWaypoint: some Gesture {
//        DragGesture()
//            .targetedToAnyEntity()
//            .onChanged { value in
//                value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
//            }
//    }
    
    func tapToTeleport(value: EntityTargetValue<TapGesture.Value>) {
        guard let sceneContent = self.root else { return }
        
        // Calculate the vector from the origin to the tapped position
        let vectorToTap = value.entity.position
        
        // Normalize the vector to get a direction from the origin to the tapped position
        let direction = normalize(vectorToTap)
        
        // Calculate the distance (or magnitude) between the origin and the tapped position
        let distance = length(vectorToTap)
        
        // Calculate the new position by inverting the direction multiplied by the distance
        let newPosition = -direction * distance
        
        // Update sceneOffset's X and Z components, leave Y as it is
        sceneContent.position.x = newPosition.x
        sceneContent.position.z = newPosition.z
    }
    
    /// 엔티티 계층 구조 업데이트
    func updateEntityHierarchy() {
        guard let root = root else {
            photoGroup?.isEnabled = appModel.showPhotos
            memoGroup?.isEnabled = appModel.showMemos
            return
        }
        
        for entity in entityByAnchorID.values {
            // 1) 부모가 없으면 root 밑에 부착
            if entity.parent == nil {
                root.addChild(entity)
            }
            // 2) root 바로 아래면 정책(kind)에 맞춰 그룹으로 이동
            if entity.parent === root,
               let policy = entity.components[InteractionPolicyComponent.self] {
                switch policy.kind {
                case .photoCollection:
                    if let pg = photoGroup { pg.addChild(entity) }
                case .memo:
                    if let mg = memoGroup { mg.addChild(entity) }
                case .teleport:
                    if let tg = teleportGroup { tg.addChild(entity)}
                }
            }
        }
    }
    
    /// 그룹 가시성 업데이트
    func updateGroupVisibility() {
        photoGroup?.isEnabled = appModel.showPhotos
        memoGroup?.isEnabled = appModel.showMemos
    }
    
    // MARK: - Gesture Handlers
//
//    /// 엔티티 탭 처리
//    func handleEntityTap(_ targetEntity: Entity) {
//        let anchorUUIDString = targetEntity.name
//        guard !anchorUUIDString.isEmpty,
//              let anchorUUID = UUID(uuidString: anchorUUIDString)
//        else {
//            print("Tapped entity has no valid UUID name.")
//            return
//        }
//
//        guard let data = anchorManager.getAnchor(id: anchorUUID) else {
//            print("Tapped entity's UUID not found in AnchorManager.")
//            return
//        }
//
//        switch data.itemType {
//        case .photo:
//            tapPhotoButton(anchorUUID)
//        case .memo:
//            tapMemoButton(anchorUUID)
//        case .number:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .sticker:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .mannequin:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .drawing:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .visibility:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .board:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .back:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        case .moving:
//            tapPhotoButton(anchorUUID)  // 갈아껴야함
//        }
//    }
//
//    /// 롱프레스 제스처 처리
//    func handleLongPress(_ targetEntity: Entity) {
//        guard let anchorUUID = UUID(uuidString: targetEntity.name) else {
//            return
//        }
//
//        Task {
//            await removeWorldAnchor(by: anchorUUID)
//        }
//    }
//
//    /// Photo 버튼 탭 처리
//    func tapPhotoButton(_ anchorUUID: UUID) {
//        print("Photobutton 클릭")
//        guard let colId = anchorToCollection[anchorUUID] else {
//            print("No collection mapped for anchor \(anchorUUID)")
//            return
//        }
//        // PhotoCollectionWindow 열기
//        openWindow(id: appModel.photoCollectionWindowID, value: colId)
//        print("Opened collection window for \(colId)")
//    }
//
//    /// Memo 버튼 탭 처리
//    func tapMemoButton(_ anchorUUID: UUID) {
//        print("Memo 클릭")
//        guard let memoId = anchorToMemo[anchorUUID] else {
//            print("No memo mapped for anchor \(anchorUUID)")
//            return
//        }
//
//        openWindow(id: appModel.memoEditWindowID, value: memoId)
//    }
//
//    var teleportTapWaypoint: some Gesture {
//        TapGesture()
//            .targetedToAnyEntity()
//            .onEnded { value in
//                tapToTeleport(value: value)
//                handleEntityTap(value.entity) // 추후 리팩토링 필요
//            }
//    }
//
//    var teleportDragWaypoint: some Gesture {
//        DragGesture()
//            .targetedToAnyEntity()
//            .onChanged { value in
//                value.entity.position = value.convert(value.location3D, from: .local, to: value.entity.parent!)
//            }
//    }
//
//    func tapToTeleport(value: EntityTargetValue<TapGesture.Value>) {
//        guard let sceneContent = self.root else { return }
//
//        // Calculate the vector from the origin to the tapped position
//        let vectorToTap = value.entity.position
//
//        // Normalize the vector to get a direction from the origin to the tapped position
//        let direction = normalize(vectorToTap)
//
//        // Calculate the distance (or magnitude) between the origin and the tapped position
//        let distance = length(vectorToTap)
//
//        // Calculate the new position by inverting the direction multiplied by the distance
//        let newPosition = -direction * distance
//
//        // Update sceneOffset's X and Z components, leave Y as it is
//        sceneContent.position.x = newPosition.x
//        sceneContent.position.z = newPosition.z
//    }
}
