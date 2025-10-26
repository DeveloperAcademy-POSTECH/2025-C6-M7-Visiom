//
//  FullImmersiveView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct FullImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
            
            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)

            let card = ViewAttachmentEntity()
            card.attachment = ViewAttachmentComponent(rootView: UserControlView())            
            card.position = [0, -0.3, -0.9]
            
            headAnchor.addChild(card)
        }
    }
}

#Preview(immersionStyle: .full) {
    FullImmersiveView()
        .environment(AppModel())
}
