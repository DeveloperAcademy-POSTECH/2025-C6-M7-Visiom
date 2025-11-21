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

    @State private var isEditTitle = false
    @State private var newTitle = ""

    var body: some View {
        HStack {
            cardView

        }.swipeActions {
            swipeView
        }
    }

    private var cardView: some View {
        HStack(spacing: 24) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 35, height: 35)

                Text(String(timelineIndex))
                    .font(.system(size: 15, weight: .semibold))
            }

            VStack(alignment: .leading) {
                if isEditTitle {
                    TextField("", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 294, height: 44)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                } else {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 18)
                        .padding(.leading, 24)
                }
                HStack {
                    if occurredTime == nil {
                        timeMissingView
                    } else {
                        timeSetView
                    }
                    Spacer()
                    if isEditTitle {
                        Button("완료") {
                            timelineStore.updateTitle(id: id, to: newTitle)
                            isEditTitle = false
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 14)
                    } else {
                        Text(!isSequenceCorrect ? "시간/순서 정보 오류" : "")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 115, height: 24)
                            .background(
                                !isSequenceCorrect
                                    ? .red
                                    : .clear,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(.white)
                            .padding(.trailing, 24)
                            .padding(.bottom, 14)
                    }
                }
            }
            .frame(width: 326, height: 120)
            .background(.regularMaterial)
            .glassBackgroundEffect(
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .contentShape(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .hoverEffect()
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        !isSequenceCorrect
                            ? .red : .clear,
                    )
            )
        }
    }

    private var swipeView: some View {
        HStack {
            Button {
                timelineStore.deleteTimeline(id: id)
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("삭제")
                        .font(.system(size: 12))
                }
                .frame(width: 50)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
            .frame(width: 62)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .tint(.red)

            Button {
                newTitle = title
                isEditTitle = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                    Text("수정")
                        .font(.system(size: 12))
                }
                .frame(width: 50)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
            .frame(width: 62)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }

    private var timeMissingView: some View {
        Button {
            timelineStore.updateTimelineOccurredTime(id: id, to: Date())
        } label: {
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
        }
        .frame(width: 93, height: 36)
        .background(
            Color(
                UIColor(
                    red: 32 / 255,
                    green: 25 / 255,
                    blue: 22 / 255,
                    alpha: 1
                )
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.bottom, 14)
        .padding(.leading, 24)
    }

    // occurredTime 값이 있을 때 DatePicker를 보여주는 뷰
    private var timeSetView: some View {
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
        .environment(\.locale, Locale(identifier: "en_GB"))
        .frame(width: 93, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.bottom, 14)
        .padding(.leading, 24)
    }
}
