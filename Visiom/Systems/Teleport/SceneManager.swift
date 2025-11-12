//
//  SceneManager.swift
//  Visiom
//
//  Created by 윤창현 on 10/20/25.
//

import RealityKit
import SwiftUI

// MARK: - SceneManager
class SceneManager {
    
    // MARK: - Scene Setup
    static func setupScene(in container: Entity) {
        // 바닥 생성
        let floor = ModelEntity(
            mesh: .generatePlane(width: 100, depth: 100),
            materials: [SimpleMaterial(color: .gray.withAlphaComponent(0.3), isMetallic: false)]
        )
        floor.position = [0, 0, 0]
        container.addChild(floor)
        
        // 이동 가능한 타겟 포인트들 생성
        createMovementPoints(in: container)
    }
    
    // MARK: - Create Movement Points
    static func createMovementPoints(in container: Entity) {
        // 바닥 크기: 50x50m, 중심이 (0,0,0)이므로 범위는 -25 ~ 25
        // 마커는 가장자리에서 1m 안쪽에만 배치: -49 ~ 49
        let floorSize: Float = 9.0
        let margin: Float = 1.0
        let maxCoord = (floorSize / 2) - margin  // 49
        let minCoord = -maxCoord  // -49
        let spacing: Float = 3.0
        
        // 배치 가능한 그리드 인덱스 계산
        let minIndex = Int(ceil(minCoord / spacing))  // -16
        let maxIndex = Int(floor(maxCoord / spacing))  // 16
        
        // 이동할 수 있는 위치 마커들
        for i in minIndex...maxIndex {
            for j in minIndex...maxIndex {
                // 텔레포트 마커 (바닥)
                let marker = ModelEntity(
                    mesh: .generateCylinder(height: 0.02, radius: 0.1),
                    materials: [SimpleMaterial(color: .cyan.withAlphaComponent(0.6), isMetallic: false)]
                )
                marker.position = [Float(i) * spacing, 0.025, Float(j) * spacing]
                marker.name = "teleport_\(i)_\(j)"
                
                // InputTargetComponent와 CollisionComponent 추가
                marker.components.set(InputTargetComponent(allowedInputTypes: .indirect))
                marker.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: [0.6, 0.05, 0.6])]))
                if #available(visionOS 2.0, *) {
                    marker.components.set(HoverEffectComponent(.highlight(HoverEffectComponent.HighlightHoverEffectStyle(color: .green, strength: 2.0))))
                } else {
                    // Fallback on earlier versions
                }
                
                container.addChild(marker)
            }
        }
    }
    
    // MARK: - Update Scene Position
    static func updateScenePosition(root: Entity, position: SIMD3<Float>) {
        // 씬을 클릭한 큐브 위치의 반대 방향으로 설정
        // position이 큐브 좌표이므로, 씬을 -position으로 이동시켜 사용자가 큐브 위치에 있는 것처럼 보이게 함
        let currentY = root.position.y
        root.position = SIMD3<Float>(-position.x, -position.y, -position.z)
    }
    
    // MARK: - Update Markers Visibility
    static func updateMarkersVisibility(root: Entity, visible: Bool) {
        // 모든 텔레포트 마커의 가시성 업데이트
//        root.children.forEach { entity in
//            if entity.name.starts(with: "teleport_") {
//                entity.isEnabled = visible
//            }
//        }
        for child in root.children where child.name.starts(with: "teleport_") {
                   child.isEnabled = visible
               }
    }
}
