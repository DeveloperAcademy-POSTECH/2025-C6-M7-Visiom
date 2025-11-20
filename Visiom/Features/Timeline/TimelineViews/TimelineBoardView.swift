//
//  TimelineBoardView.swift
//  Visiom
//
//  Created by jiwon on 11/15/25.
//

import RealityKit
import SwiftUI

struct TimelineBoardView: View {
    @Environment(AppModel.self) var appModel
    @Environment(TimelineStore.self) var timelineStore

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    @State private var isCreatePopupShow = false
    @State private var newTimelineTitle: String = ""
    @State private var newTimelineDate: Date? = nil
    @State private var hasOccurredTime: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("동선 타임라인")
                    .font(.system(size: 29, weight: .bold))
                    .padding(.leading, 24)
                Spacer()
                Button {
                    newTimelineTitle = ""
                    newTimelineDate = nil
                    hasOccurredTime = false
                    isCreatePopupShow = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19))
                }
                .frame(width: 44, height: 44)
                .glassBackgroundEffect()

                Button {
                    openWindow(id: appModel.timelineShowWindowID)
                    dismissWindow(id: appModel.timelineWindowID)
                } label: {
                    Image(systemName: "play")
                        .font(.system(size: 19))
                }
                .frame(width: 44, height: 44)
                .glassBackgroundEffect()
                .padding(.leading, 8)
                .padding(.trailing, 24)
            }
            .padding(.top, 32)

            Divider()
            List {
                ForEach(timelineStore.timelines, id: \.id) { timeline in
                    TimelineCardView(
                        id: timeline.id,
                        title: timeline.title,
                        timelineIndex: timeline.timelineIndex,
                        occurredTime: timeline.occurredTime,
                        isSequenceCorrect: timeline.isSequenceCorrect
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.top, 8)
                }
                .onMove(perform: move)
            }
            .listStyle(.plain)
            .padding(.top, 8)
            .sheet(isPresented: $isCreatePopupShow) {
                createPopup
            }
            .toolbar {
                EditButton()
            }
        }
        .task {
            await timelineStore.load()
        }
    }

    private var createPopup: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    isCreatePopupShow = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .medium))
                }
                .frame(width: 44, height: 44)
                .glassBackgroundEffect()
                .padding(.trailing, 24)

                VStack(alignment: .leading) {
                    Text("동선 추가하기")
                        .font(.system(size: 24, weight: .semibold))
                }
            }
            .padding(.leading, 24)
            .padding(.top, 20)

            Divider()

            TextField("제목을 입력하세요", text: $newTimelineTitle)
                .textFieldStyle(.roundedBorder)
                .frame(width: 314, height: 44)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            HStack {
                Text("시간").font(.system(size: 18, weight: .regular))
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
                        displayedComponents: [.hourAndMinute]
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_GB"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            Button {
                let newTimeline = timelineStore.createTimeline(
                    title: newTimelineTitle.isEmpty
                        ? "범인 동선" : newTimelineTitle,
                    occurredTime: newTimelineDate
                )
                appModel.timelineToAnchorID = newTimeline.id

                isCreatePopupShow = false
            } label: {
                Text("확인")
                    .frame(width: 188, height: 52)
            }
            .glassBackgroundEffect()
            .padding(.horizontal, 87)
            .padding(.bottom, 12)

        }.frame(width: 362, height: 284)
    }

    private func move(from source: IndexSet, to destination: Int) {
        timelineStore.timelines.move(fromOffsets: source, toOffset: destination)
        timelineStore.normalizeIndices()
    }
}

#Preview {
    TimelineBoardView()
        .frame(width: 433, height: 685)
        .glassBackgroundEffect()
        .environment(AppModel())
        .environment(TimelineStore())
}
