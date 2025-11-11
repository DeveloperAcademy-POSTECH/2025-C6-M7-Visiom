////
////  ModelLoader.swift
////  Visiom
////
////  Created by 윤창현 on 10/21/25.
////
//
//import SwiftUI
//import RealityKit
//
//
//func loadModelWithTextField(
//    from modelURL: URL,
//    position: SIMD3<Float> = [0, 1, 0],
//    textFieldTransform: Transform = Transform(translation: [0, 0.2, 0.1]),
//    text: Binding<String>
//) async throws -> Entity {
//    // 모델 로드
//    let entity = try await Entity(contentsOf: modelURL)
//    entity.name = "RootModel"
//    entity.position = position
//    
//    // TextField Attachment 생성
//    let textFieldAttachment = Entity()
//    let attachment = ViewAttachmentComponent(
//        rootView: TextFieldAttachmentView(text: text, width: 200, height: 200)
//    )
//    textFieldAttachment.components.set(attachment)
//    textFieldAttachment.transform = textFieldTransform
//    
//    entity.addChild(textFieldAttachment)
//    
//    return entity
//}
