//
//  MiniMapManager.swift
//  Visiom
//
//  Created by 윤창현 on 11/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

//struct BoxData: Identifiable {
//    let id = UUID()
//    let worldPosition: SIMD3<Float>
//    let size: SIMD3<Float>
//    let color: UIColor
//}

@Observable
class MiniMapManager {
    
    var isRotated = false
    
    var entityByAnchorIDs: [UUID: Entity] = [:]
    
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
    
    func updateAnchor(entityByAnchorID: [UUID : Entity]) {
        entityByAnchorIDs = entityByAnchorID
        print("entityByAnchorIDs \(entityByAnchorID)")
    }
    
    
    
//    func updateMainScene(content: RealityViewContent) {
//        
//        // 새로 추가된 box들을 처리
//        for boxData in boxes {
//            // 이미 추가된 box인지 확인
//            if content.entities.contains(where: { $0.name == boxData.id.uuidString }) {
//                continue
//            }
//            
//            // Main view에 box 추가
//            let box = createBox(data: boxData)
//            box.name = boxData.id.uuidString
//            content.add(box)
//        }
//    }
    
//    func createBox(data: BoxData) -> ModelEntity { // 테스트용 삭제
//        let mesh = MeshResource.generateBox(size: data.size)
//        let material = SimpleMaterial(color: data.color, isMetallic: false)
//        let box = ModelEntity(mesh: mesh, materials: [material])
//        box.setPosition(data.worldPosition, relativeTo: nil)
//        return box
//    }
    
    
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
    
    func updateMiniScene(content: RealityViewContent) {
        
        // 새로 추가된 box들을 처리
//        for boxData in boxes {
//            // 이미 추가된 box인지 확인
//            if content.entities.contains(where: { $0.name == boxData.id.uuidString }) {
//                            continue
//                        }
//            
//            // Mini view에 box 추가 (1/10 스케일)
//            let box = createMiniBox(data: boxData)
//            box.name = boxData.id.uuidString
//            content.add(box)
//        }
        print("entityByAnchorIDs: \(entityByAnchorIDs)")
        for boxData in entityByAnchorIDs.values {
                    // 이미 추가된 box인지 확인
                    if content.entities.contains(where: { $0.name == boxData.name }) {
                                    continue
                                }
        
                    // Mini view에 box 추가 (1/10 스케일)
                    let box = createMiniBox(data: boxData)
                    box.name = boxData.name
                    content.add(box)
                }
    }
    
    func createMiniBox(data: Entity) -> ModelEntity { // 테스트용 삭제
        // 1/10 크기로 생성
//        let scaledSize = data.size * 0.1
        let mesh = MeshResource.generateBox(size: 0.01)
        let material = SimpleMaterial(color: .systemMint, isMetallic: false)
        let box = ModelEntity(mesh: mesh, materials: [material])
        
        // 월드 좌표를 1/10로 스케일링
//        let scaledPosition = data.worldPosition * 0.1
        let scaledPosition = data.position(relativeTo: nil)
        
        let rotatedPosition = SIMD3<Float>(
                    scaledPosition.x,
                    -scaledPosition.z,
                    scaledPosition.y
                )
        
        box.position = rotatedPosition
        
        return box
    }
    
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
