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
        timelines.insert(timeline, at: 0)
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

    // 인덱스 수정시
    func updateTimelineIndex(id: UUID, to newIndex: Int) {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return
        }
        timelines[idx].timelineIndex = newIndex
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
        scheduleSave()
    }

    //    @discardableResult
    //    func commit(id: UUID) -> Bool {
    //        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
    //            return false
    //        }
    //        let trimmedEmpty = timelines[idx].title.trimmingCharacters(
    //            in: .whitespacesAndNewlines
    //        ).isEmpty
    //        guard !trimmedEmpty else { return false }
    //        timelines[idx].updatedAt = Date()
    //        scheduleSave()
    //        return true
    //    }

    /// 삭제
    func deleteTimeline(id: UUID) {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return
        }
        timelines.remove(at: idx)
        normalizeIndices()
        scheduleSave()
    }

    /// 1,2,3,... 순서로 재정렬
    func normalizeIndices() {
        for (i, _) in timelines.enumerated() {
            timelines[i].timelineIndex = i + 1
        }
        scheduleSave()
    }

}
