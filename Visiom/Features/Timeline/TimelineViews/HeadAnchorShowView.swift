//
//  HeadAnchorShowView.swift
//  Visiom
//
//  Created by jiwon on 11/24/25.
//

import RealityKit
import SwiftUI

struct HeadAnchorShowView: View {
    @Environment(AppModel.self) var appModel
    @Environment(TimelineStore.self) var timelineStore

    var body: some View {
        RealityView { content, attachments in
            let headAnchor = AnchorEntity(.head)

            // SwiftUI 뷰(Attachment)를 가져와서 앵커에 붙이기
            if let showViewEntity = attachments.entity(for: "TimelineShowView")
            {
                // 사용자 눈 앞에서 60cm 높이 살짝 위
                showViewEntity.position = [0, 0.09, -0.6]
                headAnchor.addChild(showViewEntity)
            }
            content.add(headAnchor)
        } attachments: {
            Attachment(id: "TimelineShowView") {
                TimelineShowView()
                    .environment(appModel)
                    .environment(timelineStore)
            }
        }
    }
}
