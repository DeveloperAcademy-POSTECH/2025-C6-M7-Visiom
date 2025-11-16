//
//  TimelineCardView.swift
//  Visiom
//
//  Created by jiwon on 11/15/25.
//

import SwiftUI

struct TimelineCardView: View {

    @Environment(TimelineStore.self) var timelineStore

    let id: UUID
    let title: String
    let timelineIndex: Int
    let occurredTime: Date?  // 사건 발생 시간
    let isSequenceCorrect: Bool  // 시간에 따른 동선 성립 여부

    var body: some View {
        HStack {
            Text(String(timelineIndex))
            VStack {
                Text(title)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { occurredTime ?? Date() },
                        set: { newValue in
                            timelineStore.updateTimelineOccurredTime(
                                id: id,
                                to: newValue
                            )
                        }
                    ),
                    displayedComponents: [.hourAndMinute]
                )
            }

        }

        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 35, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect()
    }
}
