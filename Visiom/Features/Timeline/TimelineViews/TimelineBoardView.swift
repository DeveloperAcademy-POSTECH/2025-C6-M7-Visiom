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
                    isCreatePopupShow = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19))
                }
                .frame(width: 44, height: 44)
                .glassBackgroundEffect()

                Button {
                    appModel.isShowHeadAnchorOpen = true
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
                    .onTapGesture {
                        appModel.onTimelineHighlight?(timeline.id)
                    }
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
                Spacer()
                if newTimelineDate == nil {
                    HStack {
                        Text("미정")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(width: 40)
                            .padding(.leading, 6)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.leading, 6)
                            .padding(.trailing, 10)
                    }
                    .frame(width: 93, height: 36)
                    .background(.ultraThickMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                    )
                    .buttonStyle(.plain)
                    .onTapGesture {
                        newTimelineDate = Date()
                    }
                } else {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { newTimelineDate ?? Date() },
                            set: { newTimelineDate = $0 }
                        ),
                        displayedComponents: [.hourAndMinute]
                    )
                    .background(.ultraThickMaterial)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_GB"))
                    .frame(width: 93, height: 36)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                    )
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
                appModel.itemAdd = .timeline
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
