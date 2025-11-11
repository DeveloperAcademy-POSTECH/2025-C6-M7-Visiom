//
//  EntityManager.swift
//  Visiom
//
//  Created by 윤창현 on 11/3/25.
//
// 완료

import SwiftUI
import RealityKit
import Observation

// Entity 정보를 관리하는 모델
struct EntityInfo: Identifiable {
    let id = UUID()
    let name: String
    let entity: ModelEntity
    let type: EntityType
}

enum EntityType {
    case sphere, box
}

// Observation 프레임워크를 사용한 데이터 관리
@MainActor
@Observable
class EntityManager {
    var entities: [EntityInfo] = []
    
    func addEntity(_ info: EntityInfo) {
        entities.append(info)
    }
    
    func removeEntity(at offsets: IndexSet) {
            for index in offsets {
                // RealityKit Scene에서 Entity 제거
                entities[index].entity.removeFromParent()
            }
            // 배열에서 제거
            entities.remove(atOffsets: offsets)
        }
    
    func moveEntity(from source: IndexSet, to destination: Int) {
            entities.move(fromOffsets: source, toOffset: destination)
    }
    
    func animateEntity(_ info: EntityInfo) {
        // 회전 애니메이션
        let rotation = Transform(
            pitch: 0,
            yaw: .pi * 2,
            roll: 0
        )
        
        var transform = info.entity.transform
        transform.rotation = rotation.rotation
        
        info.entity.move(
            to: transform,
            relativeTo: info.entity.parent,
            duration: 1.0,
            timingFunction: .easeInOut
        )
        
        // 점프 애니메이션
        let originalY = info.entity.position.y
        var upTransform = info.entity.transform
        upTransform.translation.y = originalY + 0.2
        
        info.entity.move(
            to: upTransform,
            relativeTo: info.entity.parent,
            duration: 0.5,
            timingFunction: .easeOut
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var downTransform = info.entity.transform
            downTransform.translation.y = originalY
            
            info.entity.move(
                to: downTransform,
                relativeTo: info.entity.parent,
                duration: 0.5,
                timingFunction: .easeIn
            )
        }
    }
}
