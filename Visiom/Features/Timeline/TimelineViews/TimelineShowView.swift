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
                    dismissWindow(id: appModel.timelineShowWindowID)
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
                }.glassBackgroundEffect()

                Spacer()

                Button {
                    if let id = timelineStore.nextTimelineID() {
                        appModel.onTimelineShow?(id)
                    }
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 29, weight: .regular))
                        .frame(width: 90, height: 64)
                }.glassBackgroundEffect()
            }
            .padding(.horizontal, 36)
            .padding(.top, 16)
        }
    }
}

#Preview {
    TimelineShowView()
        .environment(AppModel())
        .environment(TimelineStore())
}
