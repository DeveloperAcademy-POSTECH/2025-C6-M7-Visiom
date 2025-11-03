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

struct BloodStickerComponent: Component, Codable {}

enum AREntityFactory {

    /// 사진 버튼 엔티티 생성
    static func createPhotoButton() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateCylinder(
                height: ARConstants.Dimensions.photoButtonHeight,
                radius: ARConstants.Dimensions.photoButtonRadius
            ),
            materials: [
                SimpleMaterial(
                    color: ARConstants.Colors.photoButton,
                    isMetallic: false
                )
            ]
        )

        // 콜리전 및 인터랙션 설정
        let collision = CollisionComponent(shapes: [
            .generateSphere(radius: ARConstants.Dimensions.photoButtonRadius)
        ])
        let input = InputTargetComponent()
        entity.components.set([collision, input])

        // 회전 적용
        entity.transform.rotation = ARConstants.Rotation.photoButtonRotation

        return entity
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
        clone.components.set([InputTargetComponent(), BloodStickerComponent()])

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

    /// 제어 패널 뷰 엔티티 생성
    static func createControlPanel(
        appModel: AppModel
    ) -> ViewAttachmentEntity {
        let entity = ViewAttachmentEntity()
        entity.attachment = ViewAttachmentComponent(
            rootView: UserControlView()
                .environment(appModel)
        )
        entity.position = ARConstants.Position.controlPanelPosition
        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: true)

        return entity
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

    /// 데이터로부터 엔티티 생성
    static func createEntity(for itemType: UserControlItem) async -> ModelEntity
    {
        switch itemType {
        case .photo:
            return createPhotoButton()
        case .memo:
            return createMemoBox()
        case .number:
            return createPhotoButton()
        case .sticker:
            do {
                return try await createBooldSticker()
            } catch {
                print("Failed to create sticker entity: \(error)")
                return createPhotoButton()
            }
        case .mannequin:
            return createPhotoButton()
        case .drawing:
            return createPhotoButton()
        case .visibility:
            return createPhotoButton()
        case .board:
            return createPhotoButton()
        case .back:
            return createPhotoButton()
        case .moving:
            return createPhotoButton()
        }
    }
}
