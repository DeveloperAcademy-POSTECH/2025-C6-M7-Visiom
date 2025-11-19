//
//  MiniMapManager.swift
//  Visiom
//
//  Created by 윤창현 on 11/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent


@Observable
class MiniMapManager {
    
    // 화면 90도 전환 상태 관리 변수
    var isRotated = false
    
    // 앵커 위치 임시 저장 배열
    var entityByAnchorIDs: [UUID:Entity] = [:]
    
    // 미리 로드된 Entity 캐싱
    var cachedChrimeScene: Entity?
    
    // immersive 화면
    @MainActor
    func setupMainScene(content: RealityViewContent) async {
        // ChrimeScene 로드 및 추가
        if let scene = cachedChrimeScene?.clone(recursive: true) {
            scene.position = .zero
            scene.name = "MainChrimeScene"
            content.add(scene)
        } else {
            // 캐시에 없으면 로드
            do {
                let scene = try await Entity(named: "ChrimeScene",
                                             in: realityKitContentBundle)
                scene.name = "MainChrimeScene"
                content.add(scene)
            
                // 캐싱 (다음번 사용을 위해)
                if cachedChrimeScene == nil {
                    cachedChrimeScene = scene.clone(recursive: true)
                }
            } catch {
                print("Failed to load ChrimeScene: \(error)")
            }
        }
    }

    // mixedImmersive에서 사용하는 entityByAnchorID를 entityByAnchorIDs로 넣기
    func updateAnchor(entityByAnchorID: [UUID : Entity]) {
        entityByAnchorIDs = entityByAnchorID
        print("entityByAnchorIDs \(entityByAnchorID)")
    }
    
    
    // 미니맵 화면
    @MainActor
    func setupMiniScene(content: RealityViewContent) async {
        
        // ChrimeScene 로드 및 추가 (clone 사용)
        if let scene = cachedChrimeScene?.clone(recursive: true) {
            // 1/10 크기로 스케일링
            scene.scale = [0.1, 0.1, 0.1]
            scene.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            scene.name = "MiniChrimeScene" // 식별을 위한 이름 추가
            content.add(scene)
        } else {
            // 캐시에 없으면 로드
            do {
                let scene = try await Entity(named: "ChrimeScene",
                                             in: realityKitContentBundle)
                scene.scale = [0.1, 0.1, 0.1]
                scene.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                scene.name = "MiniChrimeScene" // 식별을 위한 이름 추가
                content.add(scene)
            } catch {
                print("Failed to load ChrimeScene: \(error)")
            }
        }
    }
    
    // 미니맵 Anchor 업데이트
    func updateMiniScene(content: RealityViewContent) {
        
        for entity in entityByAnchorIDs.values {
            
            if content.entities.contains(where: { $0.id == entity.id}) {
                continue
            }
            
            let marker = createMiniBox(data: entity)
            marker.name = "\(entity.id)"
            content.add(marker)
            
        }
    }
    
    // Anchor 위치 정보를 작은 상자로 표시
    func createMiniBox(data: Entity) -> ModelEntity { // 테스트용 삭제
        // 1/10 크기로 생성
        let mesh = MeshResource.generateBox(size: 0.01)
        let material = SimpleMaterial(color: .systemMint, isMetallic: false)
        let box = ModelEntity(mesh: mesh, materials: [material])
        
        // 월드 좌표를 1/10로 스케일링
        let scaledPosition = data.position(relativeTo: nil) * 0.1
        
        let rotatedPosition = SIMD3<Float>(
                    scaledPosition.x,
                    -scaledPosition.z,
                    scaledPosition.y
                )
        
        box.position = rotatedPosition
        
        return box
    }
    
    // 화면을 90도로 변환하는 함수 
    func orientationChange90Degrees(content: RealityViewContent) {
        // 엔티티 찾기
        guard let entity = content.entities.first(where: { $0.name == "MainChrimeScene" }) else {
            return
        }
        
        // 회전 애니메이션
        let scale: simd_float3
        let targetRotation: simd_quatf
        let translation: simd_float3
        if isRotated {
            // 90도 회전 (X축 기준)
            scale = [0.5, 0.5, 0.5]
            targetRotation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            translation = [0, 0, -2]
        } else {
            // 원래 위치로 복귀
            scale = [1, 1, 1]
            targetRotation = simd_quatf(angle: 0, axis: [1, 0, 0])
            translation = .zero
        }
        
        // 애니메이션과 함께 회전
        entity.move(
            to: Transform(
                scale: scale,
                rotation: targetRotation,
                translation: translation
            ),
            relativeTo: entity.parent,
            duration: 0.5,
            timingFunction: .easeInOut
        )
    }
    
    // Entity 미리 로드
    @MainActor
    func preloadChrimeScene() async {
        guard cachedChrimeScene == nil else { return }
        
        do {
            cachedChrimeScene = try await Entity(named: "ChrimeScene",
                                                  in: realityKitContentBundle)
        } catch {
            print("Failed to load ChrimeScene: \(error)")
        }
    }
    
}
