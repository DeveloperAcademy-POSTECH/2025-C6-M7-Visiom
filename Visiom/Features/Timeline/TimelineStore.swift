//
//  TimelineStore.swift
//  Visiom
//
//  Created by jiwon on 11/14/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class TimelineStore {
    private let persistence = PersistenceActor()
    var timelines: [Timeline] = []

    func load() async {
        do {
            let url = try FileLocations.timelinesIndexFile()
            let decoded: [Timeline] = try await persistence.load(from: url)
            self.timelines = decoded
        } catch {
            print("Load timelines error:", error)
            self.timelines = []
        }
    }

    // MARK: - Save batching
    private func scheduleSave() {
        let snapshot = self.timelines
        guard let url = try? FileLocations.timelinesIndexFile() else { return }
        Task {
            await persistence.enqueueWrite(snapshot, to: url)
        }
    }

    func flushSaves() async {
        await persistence.flush()
    }

    // MARK: - Query
    func timeline(id: UUID) -> Timeline? {
        timelines.first(where: { $0.id == id })
    }

    func checkSequenceCorrectness() {
        // timelineIndex 순서로 정렬 (배열 내 위치)
        let sortedTimelines = timelines.sorted {
            $0.timelineIndex < $1.timelineIndex
        }

        var lastOccurredTime: Date? = nil  // 시간이 설정된 항목 중 가장 최근에 확인한 시간
        var needsSave = false  // isSequenceCorrect 값이 변경되었는지 추적

        // 순서대로 순회하며 시간 순서를 검사
        for timeline in sortedTimelines {
            // 원본 배열에서 해당 항목의 인덱스 찾기
            guard
                let idx = timelines.firstIndex(where: { $0.id == timeline.id })
            else { continue }

            var currentSequenceCorrect = true

            if let currentTime = timeline.occurredTime {
                // 시간이 설정되어 있으면 바로 앞서 나온 시간과 비교
                if let prevTime = lastOccurredTime, currentTime < prevTime {
                    // 현재 시간이 이전 시간보다 빠르다면 -> 순서 오류
                    currentSequenceCorrect = false
                }
                // 현재 시간을 다음 항목의 비교 기준으로 업데이트
                lastOccurredTime = currentTime
            } else {
                // 시간이 설정되지 않으면 순서 오류 검사에서 제외
                currentSequenceCorrect = true
            }

            // isSequenceCorrect 상태 업데이트
            if timelines[idx].isSequenceCorrect != currentSequenceCorrect {
                timelines[idx].isSequenceCorrect = currentSequenceCorrect
                timelines[idx].updatedAt = Date()
                needsSave = true
            }
        }

        if needsSave {
            scheduleSave()
        }
    }

    // MARK: - CRUD
    @discardableResult
    func createTimeline(
        id: UUID = UUID(),
        title: String = "",
        occurredTime: Date? = nil,
    ) -> Timeline {
        let now = Date()
        let timeline = Timeline(
            id: id,
            title: title,
            timelineIndex: timelines.count + 1,
            occurredTime: occurredTime,
            isSequenceCorrect: true,
            createdAt: now,
            updatedAt: now,
        )
        timelines.append(timeline)
        scheduleSave()
        return timeline
    }

    /// 텍스트 변경
    func updateTitle(id: UUID, to newText: String) {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return
        }
        timelines[idx].title = newText
        timelines[idx].updatedAt = Date()
        scheduleSave()
    }

    // 사건발생 시간 수정시
    func updateTimelineOccurredTime(id: UUID, to newTime: Date?) {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return
        }
        timelines[idx].occurredTime = newTime
        timelines[idx].updatedAt = Date()
        checkSequenceCorrectness()
        scheduleSave()
    }

    /// 삭제
    func deleteTimeline(id: UUID) {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return
        }
        timelines.remove(at: idx)
        normalizeIndices()
    }

    /// 1,2,3,... 순서로 재정렬
    func normalizeIndices() {
        for (i, _) in timelines.enumerated() {
            timelines[i].timelineIndex = i + 1
        }
        checkSequenceCorrectness()
        scheduleSave()
    }

}
