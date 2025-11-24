//
//  TimelineShowView.swift
//  Visiom
//
//  Created by jiwon on 11/18/25.
//
import SwiftUI

struct TimelineShowView: View {
    @Environment(AppModel.self) var appModel
    @Environment(TimelineStore.self) var timelineStore

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    openWindow(id: appModel.timelineWindowID)
                    appModel.isShowHeadAnchorOpen = false
                } label: {
                    Image(systemName: "chevron.left")
                }
                .frame(width: 44, height: 44)
                .glassBackgroundEffect()
                .padding(.trailing, 24)

                Text("Show")
                    .font(.system(size: 32, weight: .bold))
            }.padding(.leading, 32)
            Divider()
            HStack {
                Button {
                    if let id = timelineStore.previousTimelineID() {
                        appModel.onTimelineShow?(id)
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 29, weight: .regular))
                        .frame(width: 90, height: 64)
                }
                .glassBackgroundEffect()
                .disabled(!timelineStore.canGoToPreviousTimeline)

                Spacer()

                Button {
                    if let id = timelineStore.nextTimelineID() {
                        appModel.onTimelineShow?(id)
                    }
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 29, weight: .regular))
                        .frame(width: 90, height: 64)
                }
                .glassBackgroundEffect()
                .disabled(!timelineStore.canGoToNextTimeline)
            }
            .padding(.horizontal, 36)
            .padding(.top, 16)
        }
        .frame(width: 388, height: 190)
        .glassBackgroundEffect()
        .task {
            try? await Task.sleep(for: .milliseconds(200))

            // 첫 번째 타임라인 ID를 가져와서 이동
            if let id = timelineStore.firstTimelineID() {
                print("첫 번째 마커로 이동: \(id)")
                appModel.onTimelineShow?(id)
            } else {
                print("첫 번째 마커를 찾을 수 없음")
            }
        }
    }
}
