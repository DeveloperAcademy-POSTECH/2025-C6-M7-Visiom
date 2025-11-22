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
    
    var anchorRecords : [AnchorRecord] = []
    
    // 미리 로드된 Entity 캐싱
    var cachedCrimeScene: Entity?
    
    // 미리 로드된 마커 Entity 캐싱
    var cachedMiniMapMarker: Entity?
    
    // immersive 화면
    @MainActor
    func setupMainScene(content: RealityViewContent) async {
        // ChrimeScene 로드 및 추가
        if let scene = cachedCrimeScene?.clone(recursive: true) {
            scene.position = .zero
            
            scene.name = "Immersive"
            content.add(scene)
        } else {
            // 캐시에 없으면 로드
            do {
                let scene = try await Entity(named: "light_crime_scene",
                                             in: realityKitContentBundle)
                scene.name = "Immersive"
                content.add(scene)
            
                // 캐싱 (다음번 사용을 위해)
                if cachedCrimeScene == nil {
                    cachedCrimeScene = scene.clone(recursive: true)
                }
            } catch {
                print("Failed to load ChrimeScene: \(error)")
            }
        }
    }
    
    // AnchorRecord 데이터 업데이트
    func updateAnchor(anchorRecord: AnchorRecord) {
        anchorRecords.append(anchorRecord)
        print("AnchorRecord \(anchorRecord)")
    }
    
    // 미니맵 화면
    @MainActor
    func setupMiniScene(content: RealityViewContent) async {
        
        // ChrimeScene 로드 및 추가 (clone 사용)
        if let scene = cachedCrimeScene?.clone(recursive: true) {
            // 1/10 크기로 스케일링
            scene.scale = [0.1, 0.1, 0.1]
            scene.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            scene.name = "miniImmersive" // 식별을 위한 이름 추가
            content.add(scene)
        } else {
            // 캐시에 없으면 로드
            do {
                let scene = try await Entity(named: "minimap_55",
                                             in: realityKitContentBundle)
                scene.scale = [0.1, 0.1, 0.1]
                scene.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                scene.position.z = -0.1
                scene.name = "miniImmersive" // 식별을 위한 이름 추가
                content.add(scene)
            } catch {
                print("Failed to load ChrimeScene: \(error)")
            }
            
            do {
                cachedMiniMapMarker = try await Entity(named: "WMark",
                                                      in: realityKitContentBundle)
                cachedMiniMapMarker?.scale = [0.1, 0.1, 0.1]
            } catch {
                print("Failed to load MiniMapMarker: \(error)")
            }
        }
    }
    
    // 미니맵 update 클로저에 사용
    func updateMiniScene(content: RealityViewContent) {
        
        for anchor in anchorRecords {
            if content.entities.contains(where: { $0.name == "marker_\(anchor.id)" }) {
                continue
            }
            
            let marker = createMiniBox(anchor: anchor)
            marker.name = "marker_\(anchor.id)"
            
            content.add(marker)
        }
    }
    
    // 미니맵에 entity 생성하는 함수
    func createMiniBox(anchor: AnchorRecord) -> Entity {
        // 1/10 크기로 생성
//        let scaledSize = data.size * 0.1
        let position = anchor.worldMatrix
        let mesh = MeshResource.generateBox(size: 0.01)
        let material = SimpleMaterial(color: .systemMint, isMetallic: false)
        let box = ModelEntity(mesh: mesh, materials: [material])
        
        let marker = cachedMiniMapMarker?.clone(recursive: true) ?? box
        
        marker.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
        
        // 월드 앵커를 SIMD3 변환
        let translation = SIMD3<Float>(position.columns.3.x, position.columns.3.y, position.columns.3.z)
        // 스케일에 맞춰 좌표 수정
        let scaledPosition = translation * 0.1

        
//        let rotatedPosition = SIMD3<Float>(
//                    scaledPosition.x,
////                    -scaledPosition.z,
//                    0,
//                    scaledPosition.y
//                )
        
//        marker.position = rotatedPosition
        marker.position = scaledPosition
        
        return marker
    }
    
    // 화면을 90도로 변환하는 함수 
    func orientationChange90Degrees(content: RealityViewContent) {
        // 엔티티 찾기
        guard let entity = content.entities.first(where: { $0.name == "Immersive" }) else {
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
        guard cachedCrimeScene == nil else { return }
        
        do {
            cachedCrimeScene = try await Entity(named: "Immersive",
                                                  in: realityKitContentBundle)
        } catch {
            print("Failed to load CrimeScene: \(error)")
        }

    }
    
}
