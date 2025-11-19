//
//  ReorderableTimelineCardView.swift
//  Visiom
//
//  Created by jiwon on 11/16/25.
//

import SwiftUI

struct ReorderableTimelineCardView<Content: View>: View {

    @Environment(TimelineStore.self) var timelineStore

    let item: Timeline
    let content: () -> Content

    @GestureState private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        content()
            .opacity(isDragging ? 0.7 : 1)
            .scaleEffect(isDragging ? 1.02 : 1)
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                        onDragChanged(translation: value.translation)
                    }
                    .onEnded { value in
                        onDragEnded()
                    }
            )
            .animation(.easeInOut(duration: 0.15), value: isDragging)
    }

    private func onDragChanged(translation: CGSize) {
        isDragging = true

        guard
            let fromIndex = timelineStore.timelines.firstIndex(where: {
                $0.id == item.id
            })
        else { return }

        // 드래그한 거리 기준으로 위치 계산
        let itemHeight: CGFloat = 110
        let moved = Int((translation.height / itemHeight).rounded())

        let toIndex = fromIndex + moved

        guard toIndex >= 0,
            toIndex < timelineStore.timelines.count,
            toIndex != fromIndex
        else { return }

        withAnimation(.spring()) {
            let element = timelineStore.timelines.remove(at: fromIndex)
            timelineStore.timelines.insert(element, at: toIndex)
            timelineStore.normalizeIndices()  // index 자동 정렬
        }
    }

    private func onDragEnded() {
        isDragging = false
        timelineStore.normalizeIndices()
    }
}
