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
    static func createEntity(for kind: EntityKind) async -> ModelEntity {
        switch kind {
        case .photoCollection:
            do {
                return try await createPhotoCollectionButton()
            } catch {
                print("Failed to create photo entity: \(error)")
                return ModelEntity()
            }
        case .memo:
            do {
                return try await createMemoBox()
            } catch {
                print("Failed to create memo entity: \(error)")
                return ModelEntity()
            }
        case .teleport:
            do{
                return try await createTeleport()
            } catch {
                print("Failed to create teleport entity: \(error)")
                return ModelEntity()
            }
        case .timeline:
            do {
                return try await createTimeline()
            } catch {
                print("Failed to create timeline entity: \(error)")
                return ModelEntity()
            }
        }
    }
    
    /// 사진 버튼 엔티티 생성
    static func createPhotoCollectionButton() async throws -> ModelEntity {
        
        // 원본 entity 로드 (ModelEntity라고 가정하지 않음)
        let root = try await Entity(named: "photo", in: realityKitContentBundle)
        
        // mesh 가진 Entity 찾기 (ModelComponent 보유한 첫 엔티티 탐색)
        guard let meshEntity = findFirstEntityWithModelComponent(in: root)
        else {
            fatalError("photo usdz 안에서 ModelComponent 가진 entity 못 찾음")
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
            fatalError("memo usdz 안에서 ModelComponent 가진 entity 못 찾음")
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
    
    static func createTeleport() async throws -> ModelEntity {
        let root = try await Entity(
            named: "teleport",
            in: realityKitContentBundle
        )
        
        // mesh 가진 Entity 찾기 (ModelComponent 보유한 첫 엔티티 탐색)
        guard let meshEntity = findFirstEntityWithModelComponent(in: root)
        else {
            fatalError("timeline usdz 안에서 ModelComponent 가진 entity 못 찾음")
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
        
        
        
        let collisionComponent = CollisionComponent(
            shapes: [ShapeResource.generateBox(size:  SIMD3<Float>(0.1, 0.1, 0.1))]
        )
        let inputTargetComponent = InputTargetComponent()
        
        let hoverEffectComponent = HoverEffectComponent(.highlight(HoverEffectComponent.HighlightHoverEffectStyle(
            color: .white, strength: 2.0
        )))
        
        entity.components.set([collisionComponent, inputTargetComponent, hoverEffectComponent])
        entity.transform.rotation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(1, 0, 0))
        
        return entity
        
        
    }
    
    static func createTimeline() async throws -> ModelEntity {
        let root = try await Entity(
            named: "timeline",
            in: realityKitContentBundle
        )
        
        // mesh 가진 Entity 찾기 (ModelComponent 보유한 첫 엔티티 탐색)
        guard let meshEntity = findFirstEntityWithModelComponent(in: root)
        else {
            fatalError("timeline usdz 안에서 ModelComponent 가진 entity 못 찾음")
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
                .font(
                    .system(
                        size: ARConstants.TextFormatting.memoTextSize,
                        weight: ARConstants.TextFormatting.memoTextWeight
                    )
                )
        )
        return entity
    }
}
