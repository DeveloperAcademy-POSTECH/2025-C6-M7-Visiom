//
//  AREntity.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct ScaleRotationComponent: Component, Codable {}
struct OnlyScaleComponent: Component, Codable {}

enum AREntityFactory {
    
    /// 데이터로부터 엔티티 생성
    static func createEntity(for kind: EntityKind) async -> ModelEntity
    {
        switch kind {
        case .photoCollection:
            do {
                return try await createPhotoCollectionButton()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return ModelEntity()
            }
        case .memo:
            do {
                return try await createMemoBox()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return ModelEntity()
            }
        case .teleport:
            return createTeleport()
        }
    }
    
    /// 사진 버튼 엔티티 생성
    static func createPhotoCollectionButton() async throws -> ModelEntity {
        
        // 원본 entity 로드 (ModelEntity라고 가정하지 않음)
        let root = try await Entity(named: "btn", in: realityKitContentBundle)
        
        // mesh 가진 Entity 찾기 (ModelComponent 보유한 첫 엔티티 탐색)
        guard let meshEntity = findFirstEntityWithModelComponent(in: root)
        else {
            fatalError("arrow usdz 안에서 ModelComponent 가진 entity 못 찾음")
        }
        
        // ModelEntity 확보 - 이미 ModelEntity면 캐스팅 아니면 ModelComponent로 새 ModelEntity 구성
        let modelEntity: ModelEntity
        if let casted = meshEntity as? ModelEntity {
            modelEntity = casted
        } else if let modelComp = meshEntity.components[ModelComponent.self] {
            modelEntity = ModelEntity()
            modelEntity.components.set(modelComp)
        } else {
            fatalError("ModelComponent를 가진 엔티티를 찾았지만 구성 추출에 실패")
        }
        
        let entity = modelEntity.clone(recursive: true)
        
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent())
        
        return entity
    }
    
    /// 메모 박스 엔티티 생성
    static func createMemoBox() async throws -> ModelEntity {
        let root = try await Entity(named: "memo", in: realityKitContentBundle)
        
        // mesh 가진 Entity 찾기 (ModelComponent 보유한 첫 엔티티 탐색)
        guard let meshEntity = findFirstEntityWithModelComponent(in: root)
        else {
            fatalError("arrow usdz 안에서 ModelComponent 가진 entity 못 찾음")
        }
        
        // ModelEntity 확보 - 이미 ModelEntity면 캐스팅 아니면 ModelComponent로 새 ModelEntity 구성
        let modelEntity: ModelEntity
        if let casted = meshEntity as? ModelEntity {
            modelEntity = casted
        } else if let modelComp = meshEntity.components[ModelComponent.self] {
            modelEntity = ModelEntity()
            modelEntity.components.set(modelComp)
        } else {
            fatalError("ModelComponent를 가진 엔티티를 찾았지만 구성 추출에 실패")
        }
        
        let entity = modelEntity.clone(recursive: true)
        
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent())
        
        return entity
    }
    
    static func createTeleport() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: 0.1)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // 콜리전 및 인터랙션 설정
        let collision = CollisionComponent(shapes: [
            .generateBox(size: [0.28, 0.05, 0.28])
        ])
        let input = InputTargetComponent()
        entity.components.set([collision, input])
        
        return entity
    }
    
    // 재귀적으로 첫 ModelComponent 가진 엔티티 찾기
    private static func findFirstEntityWithModelComponent(in entity: Entity)
    -> Entity?
    {
        if entity.components.has(ModelComponent.self) {
            return entity
        }
        for child in entity.children {
            if let found = findFirstEntityWithModelComponent(in: child) {
                return found
            }
        }
        return nil
    }
    
    /// 메모 텍스트 오버레이 생성
    static func createMemoTextOverlay(text: String) -> ViewAttachmentEntity {
        let entity = ViewAttachmentEntity()
        entity.attachment = ViewAttachmentComponent(
            rootView: Text(text)
                .frame(
                    width: ARConstants.TextFormatting.memoFrameWidth,
                    height: ARConstants.TextFormatting.memoFrameHeight
                )
                .background(
                    .regularMaterial.opacity(
                        ARConstants.TextFormatting.backgroundOpacity
                    )
                )
                .foregroundColor(.black)
                .font(.system(size: ARConstants.TextFormatting.memoTextSize))
        )
        return entity
    }
}
