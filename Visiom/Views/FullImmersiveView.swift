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
        RealityView { content, attachments in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            }
            
            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)
            
            if let card = attachments.entity(for: "userControlAttachment") {
                card.position = [0, -0.3, -0.9]
                card.components.set(BillboardComponent())
                headAnchor.addChild(card)
            }
        } attachments: {
            Attachment(id: "userControlAttachment") { UserControlView() }
        }
    }
}

#Preview(immersionStyle: .full) {
    FullImmersiveView()
        .environment(AppModel())
}
