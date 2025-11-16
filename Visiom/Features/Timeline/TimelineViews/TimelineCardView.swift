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

    private var timeMissingView: some View {
        Button {
            timelineStore.updateTimelineOccurredTime(id: id, to: Date())
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text("모름 (시간 설정)")
            }
            .foregroundColor(.secondary)
        }
    }

    // occurredTime 값이 있을 때 DatePicker를 보여주는 뷰
    private var timeSetView: some View {
        HStack {
            DatePicker(
                "",
                selection: Binding(
                    // get: 값이 있으므로 occurredTime!를 사용하고, 안전하게 nil 병합을 Date()로 유지
                    get: { occurredTime ?? Date() },
                    // set: 사용자가 시간을 바꿀 때만 업데이트를 진행
                    set: { newValue in
                        timelineStore.updateTimelineOccurredTime(
                            id: id,
                            to: newValue
                        )
                    }
                ),
                displayedComponents: [.hourAndMinute]
            )
            .labelsHidden()

            // 시간을 다시 "모름" 상태로 되돌리는 버튼
            Button {
                timelineStore.updateTimelineOccurredTime(id: id, to: nil)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }

    var body: some View {
        HStack {
            Text(String(timelineIndex))
            VStack {
                Text(title)
                Text(!isSequenceCorrect ? "시간이 성립하지 않습니다" : "")
            }
            if occurredTime == nil {
                timeMissingView
            } else {
                timeSetView
            }
            Button {
                timelineStore.deleteTimeline(id: id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 35, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect()
        .overlay(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .stroke(
                    !isSequenceCorrect ? Color.red : Color.clear,
                )
        )
    }
}
