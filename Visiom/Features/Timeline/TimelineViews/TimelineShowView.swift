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

    var body: some View {
        HStack {
            Button {
                if let id = timelineStore.previousTimelineID() {
                    appModel.onTimelineShow?(id)
                }
            } label: {
                Image(systemName: "arrow.left")
            }

            Button {
                if let id = timelineStore.nextTimelineID() {
                    appModel.onTimelineShow?(id)
                }
            } label: {
                Image(systemName: "arrow.right")
            }
        }
    }
}
