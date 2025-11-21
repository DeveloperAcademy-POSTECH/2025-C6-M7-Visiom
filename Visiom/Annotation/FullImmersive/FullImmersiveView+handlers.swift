////
////  Ext+FullImmersiveView.swift
////  Visiom
////
////  Created by 윤창현 on 10/31/25.
////
//
//import ARKit
//import RealityKit
//import SwiftUI
//
//// MARK: - Handlers Extension
//extension FullImmersiveView {
//    
//    /// 엔티티 계층 구조 업데이트
//    func updateEntityHierarchy() {
//        guard let root = root else {
//            photoGroup?.isEnabled = appModel.showPhotos
//            memoGroup?.isEnabled = appModel.showMemos
//            return
//        }
//
//        for entity in entityByAnchorID.values {
//            // 1) 부모가 없으면 root 밑에 부착
//            if entity.parent == nil {
//                root.addChild(entity)
//            }
//            // 2) root 바로 아래면 정책(kind)에 맞춰 그룹으로 이동
//            if entity.parent === root,
//                let policy = entity.components[InteractionPolicyComponent.self]
//            {
//                switch policy.kind {
//                case .photoCollection:
//                    if let pg = photoGroup { pg.addChild(entity) }
//                case .memo:
//                    if let mg = memoGroup { mg.addChild(entity) }
//                case .teleport:
//                    if let tg = teleportGroup { tg.addChild(entity) }
//                case .timeline:
//                    if let tg = timelineGroup { tg.addChild(entity) }
//                }
//            }
//        }
//    }
//
//    /// 그룹 가시성 업데이트
//    func updateGroupVisibility() {
//        photoGroup?.isEnabled = appModel.showPhotos
//        memoGroup?.isEnabled = appModel.showMemos
//    }
//}
