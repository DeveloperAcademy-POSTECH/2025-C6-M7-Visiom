//
//  TimelineView.swift
//  Visiom
//
//  Created by jiwon on 11/15/25.
//

import RealityKit
import SwiftUI

struct TimelineView: View {
    @Environment(AppModel.self) var appModel
    @Environment(TimelineStore.self) var timelineStore

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("타임라인")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(0)
            }
            Button {
                let newTimeline = timelineStore.createTimeline(
                    title: "새 타임라인",
                    occurredTime: nil,
                )
                appModel.timelineToAnchorID = newTimeline.id
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
            }

            Divider()

            ScrollView(.vertical) {
                LazyVStack(spacing: 24) {
                    ForEach(timelineStore.timelines, id: \.id) { timeline in
                        ReorderableTimelineCardView(item: timeline) {
                            TimelineCardView(
                                id: timeline.id,
                                title: timeline.title,
                                timelineIndex: timeline.timelineIndex,
                                occurredTime: timeline.occurredTime,
                                isSequenceCorrect: timeline.isSequenceCorrect
                            )
                        }
                    }
                }
            }
        }
    }
}
