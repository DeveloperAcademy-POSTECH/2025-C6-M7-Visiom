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
    
    // MARK: - Timer 관리
    
    func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateScenePosition()
        }
    }
    
    func stopTimer() {
        updateTimer?.invalidate()
    }
    
    // MARK: - Gesture Handlers
    
    /// 엔티티 탭 처리
    func handleEntityTap(_ targetEntity: Entity) {
        let anchorUUIDString = targetEntity.name
        guard !anchorUUIDString.isEmpty,
              let anchorUUID = UUID(uuidString: anchorUUIDString)
        else {
            print("Tapped entity has no valid UUID name.")
            return
        }
        
        if let itemType = tempItemType[anchorUUID] {
            switch itemType {
            case .photo:
                tapPhotoButton(anchorUUID)
            case .memo:
                tapMemoButton(memoId: anchorUUID)
            }
        } else {
            print("Tapped entity's UUID not found in tempItemType.")
        }
    }
    
    /// 롱프레스 제스처 처리
    func handleLongPress(_ targetEntity: Entity) {
        guard let anchorUUID = UUID(uuidString: targetEntity.name) else {
            return
        }
        
        Task {
            await removeWorldAnchor(by: anchorUUID)
        }
    }
    
    /// Teleport 마커 탭 처리
    func handleTap(on entity: Entity) {
        let name = entity.name
        print("Tapped on: \(name)")
        
        // 텔레포트 마커 탭 처리
        if name.starts(with: "teleport_") {
            // 마커의 위치로 텔레포트 (y=0.5로 설정)
            let cubePosition = SIMD3<Float>(entity.position.x, 0.5, entity.position.z)
            teleportTo(cubePosition)
        }
    }
    
    /// Photo 버튼 탭 처리
    func tapPhotoButton(_ anchorUUID: UUID) {
        print("ball 클릭")
        guard let colId = anchorToCollection[anchorUUID] else {
            print("No collection mapped for anchor \(anchorUUID)")
            return
        }
        // PhotoCollectionWindow 열기
        openWindow(id: appModel.photoCollectionWindowID, value: colId)
        print("Opened collection window for \(colId)")
    }
    
    /// Memo 버튼 탭 처리
    func tapMemoButton(memoId: UUID) {
        print("box 클릭, text: \(memoText[memoId] ?? "no memo")")
    }
    
    // MARK: - Teleport
    
    /// 텔레포트 이동
    func teleportTo(_ cubePosition: SIMD3<Float>) {
        position = cubePosition
        print("🌀 Teleported to cube at: \(position)")
        updateScenePosition()
    }
    
    // MARK: - Scene Updates
    
    /// 씬 위치 업데이트
    func updateScenePosition() {
        guard let root = root else { return }
        SceneManager.updateScenePosition(root: root, position: position)
    }
    
    /// 마커 가시성 업데이트
    func updateMarkersVisibility() {
        guard let root = root else { return }
        SceneManager.updateMarkersVisibility(root: root, visible: markerManager.isVisible)
    }
    
    /// 엔티티 계층 구조 업데이트
    func updateEntityHierarchy() {
        guard let root = root else {
            photoGroup?.isEnabled = appModel.showPhotos
            memoGroup?.isEnabled = appModel.showMemos
            return
        }
        
        for (uuid, data) in worldAnchorEntityData {
            // 부모가 없는 entity는 root 밑에 붙이기
            if data.entity.parent == nil {
                root.addChild(data.entity)
            }
            
            // root 밑에 있는 entity 부모 찾아주기
            if data.entity.parent === root {
                if tempItemType[uuid] == .photo, let pg = photoGroup {
                    pg.addChild(data.entity)
                } else if tempItemType[uuid] == .memo, let mg = memoGroup {
                    mg.addChild(data.entity)
                }
            }
        }
    }
    
    /// 그룹 가시성 업데이트
    func updateGroupVisibility() {
        photoGroup?.isEnabled = appModel.showPhotos
        memoGroup?.isEnabled = appModel.showMemos
    }
}
