//
//  AREntity.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import SwiftUI
import RealityKit
import ARKit

enum AREntityFactory {
    
    /// 사진 버튼 엔티티 생성
    static func createPhotoButton() -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateCylinder(
                height: ARConstants.Dimensions.photoButtonHeight,
                radius: ARConstants.Dimensions.photoButtonRadius
            ),
            materials: [SimpleMaterial(
                color: ARConstants.Colors.photoButton,
                isMetallic: false
            )]
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
            materials: [SimpleMaterial(
                color: ARConstants.Colors.memoBackground,
                isMetallic: false
            )]
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
                .background(.regularMaterial.opacity(
                    ARConstants.TextFormatting.backgroundOpacity
                ))
                .foregroundColor(.black)
                .font(.system(size: ARConstants.TextFormatting.memoTextSize))
        )
        return entity
    }
    
    /// 데이터로부터 엔티티 생성
    static func createEntity(for itemType: UserControlBar) -> ModelEntity {
        switch itemType {
        case .photo:
            return createPhotoButton()
        case .memo:
            return createMemoBox()
        }
    }
}
