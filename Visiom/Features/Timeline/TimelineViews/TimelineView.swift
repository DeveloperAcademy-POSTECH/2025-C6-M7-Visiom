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

    @State private var isCreatePopupShow = false
    @State private var newTimelineTitle: String = ""
    @State private var newTimelineDate: Date? = nil
    @State private var hasOccurredTime: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("동선 타임라인")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(0)
                Button {
                    newTimelineTitle = ""
                    newTimelineDate = nil
                    hasOccurredTime = false
                    isCreatePopupShow = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19))
                }
                Button {
                } label: {
                    Image(systemName: "play")
                        .font(.system(size: 19))
                }
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
        .sheet(isPresented: $isCreatePopupShow) {
            VStack(alignment: .leading, spacing: 20) {
                Text("새 타임라인 생성")
                    .font(.title2.bold())

                TextField("제목 입력", text: $newTimelineTitle)
                    .textFieldStyle(.roundedBorder)

                Toggle("임시 nil 일때 경우", isOn: $hasOccurredTime)
                    .onChange(of: hasOccurredTime) { oldValue, newValue in
                        if newValue && newTimelineDate == nil {
                            // 토글이 켜지면 DatePicker를 위해 현재 시간으로 초기화
                            newTimelineDate = Date()
                        } else if !newValue {
                            // 토글이 꺼지면 미정 상태를 위해 nil로 설정
                            newTimelineDate = nil
                        }
                    }

                if hasOccurredTime {
                    // DatePicker는 non-optional Binding<Date>를 요구하므로
                    // 옵셔널인 $newTimelineDate를 non-optional로 변환하는 Binding을 생성
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { newTimelineDate ?? Date() },
                            set: { newTimelineDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }

                HStack {
                    Spacer()
                    Button("x") {
                        isCreatePopupShow = false
                    }

                    Button("확인") {
                        let newTimeline = timelineStore.createTimeline(
                            title: newTimelineTitle.isEmpty
                                ? "새 타임라인" : newTimelineTitle,
                            occurredTime: newTimelineDate
                        )
                        appModel.timelineToAnchorID = newTimeline.id

                        isCreatePopupShow = false
                    }
                }
            }
        }
    }
}
