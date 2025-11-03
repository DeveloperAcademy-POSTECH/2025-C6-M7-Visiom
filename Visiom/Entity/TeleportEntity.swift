//
//  TeleportEntity.swift
//  Visiom
//
//  Created by 윤창현 on 11/3/25.
//

import SwiftUI
import RealityKit

struct TeleportEntity {
    
    // MARK: - Sphere Creation
     static func createMarker() -> ModelEntity {
         let mesh = MeshResource.generateSphere(radius: 0.1)
         let material = SimpleMaterial(color: .blue, isMetallic: true)
         let entity = ModelEntity(mesh: mesh, materials: [material])
         entity.name = "sphere"
         
         // 랜덤 위치에 배치
         entity.position = SIMD3(
             x: Float.random(in: -0.3...0.3),
             y: Float.random(in: 1.2...1.6),
             z: -1.5
         )
         
         // 충돌 및 입력 컴포넌트 추가
         entity.components.set(HoverEffectComponent())
         entity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)]))
         entity.components.set(InputTargetComponent())
         
         return entity
     }
}
