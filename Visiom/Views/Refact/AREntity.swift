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

    /// 사진 버튼 엔티티 생성
    static func createPhotoButton() async throws -> ModelEntity {

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

        let clone = modelEntity.clone(recursive: true)

        clone.generateCollisionShapes(recursive: true)
        clone.components.set(InputTargetComponent())

        return clone
    }

    /// 메모 박스 엔티티 생성
    static func createMemoBox() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateBox(
                width: ARConstants.Dimensions.memoBoxSize,
                height: ARConstants.Dimensions.memoBoxSize,
                depth: ARConstants.Dimensions.memoBoxDepth
            ),
            materials: [
                SimpleMaterial(
                    color: ARConstants.Colors.memoBackground,
                    isMetallic: false
                )
            ]
        )

        // 콜리전 및 인터랙션 설정
        let collision = CollisionComponent(shapes: [
            .generateBox(
                width: ARConstants.Dimensions.memoBoxSize,
                height: ARConstants.Dimensions.memoBoxSize,
                depth: ARConstants.Dimensions.memoBoxDepth
            )
        ])
        let input = InputTargetComponent()
        entity.components.set([collision, input])

        return entity
    }

    static func createBooldSticker() async throws -> ModelEntity {

        // 원본 entity 로드 (ModelEntity라고 가정하지 않음)
        let root = try await Entity(named: "arrow", in: realityKitContentBundle)

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

        let clone = modelEntity.clone(recursive: true)

        clone.generateCollisionShapes(recursive: true)
        clone.components.set([InputTargetComponent(), ScaleRotationComponent()])

        return clone
    }

    static func createNumberPicker() async throws -> ModelEntity {

        // 원본 entity 로드 (ModelEntity라고 가정하지 않음)
        let root = try await Entity(
            named: "picker",
            in: realityKitContentBundle
        )

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

        let clone = modelEntity.clone(recursive: true)

        clone.generateCollisionShapes(recursive: true)
        clone.components.set([InputTargetComponent(), OnlyScaleComponent()])

        return clone
    }

    static func createBody() async throws -> ModelEntity {

        // 원본 entity 로드 (ModelEntity라고 가정하지 않음)
        let root = try await Entity(named: "body", in: realityKitContentBundle)

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

        let clone = modelEntity.clone(recursive: true)

        clone.generateCollisionShapes(recursive: true)
        clone.components.set([InputTargetComponent(), ScaleRotationComponent()])

        return clone
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

//    /// 제어 패널 뷰 엔티티 생성
//    static func createControlPanel(
//        appModel: AppModel
//    ) -> ViewAttachmentEntity {
//        let entity = ViewAttachmentEntity()
//        entity.attachment = ViewAttachmentComponent(
//            rootView: UserControlView()
//                .environment(appModel)
//            
//        )
//        entity.position = ARConstants.Position.controlPanelPosition
//        entity.components.set(InputTargetComponent())
//        entity.generateCollisionShapes(recursive: true)
//
//        return entity
//    }

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
    
    
    // telepoart marker
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
    
    
    /// 데이터로부터 엔티티 생성
    static func createEntity(for itemType: UserControlItem) async -> ModelEntity
    {
        switch itemType {
        case .photo:
            do {
                return try await createPhotoButton()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return ModelEntity()
            }
        case .memo:
            return createMemoBox()
        case .number:
            do {
                return try await createNumberPicker()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return ModelEntity()
            }
        case .sticker:
            do {
                return try await createBooldSticker()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return ModelEntity()
            }
        case .mannequin:
            do {
                return try await createBody()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return ModelEntity()
            }
        case .drawing:
            return ModelEntity()
        case .visibility:
            return ModelEntity()
        case .board:
            return ModelEntity()
        case .back:
            return ModelEntity()
        case .moving:
            return ModelEntity()
        }
    }
}
