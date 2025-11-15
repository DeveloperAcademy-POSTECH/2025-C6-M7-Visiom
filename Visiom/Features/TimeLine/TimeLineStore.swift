//
//  TimeLineStore.swift
//  Visiom
//
//  Created by jiwon on 11/14/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class TimeLineStore {
    private let persistence = PersistenceActor()
    var timelines: [TimeLine] = []

    func load() async {
        do {
            let url = try FileLocations.timelinesIndexFile()
            let decoded: [TimeLine] = try await persistence.load(from: url)
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
    func timeline(id: UUID) -> TimeLine? {
        timelines.first(where: { $0.id == id })
    }

    // MARK: - CRUD
    @discardableResult
    func createTimeline(
        id: UUID = UUID(),
        title: String = "",
        timeLineIndex: Int = 0,
        occurredTime: Date = .now,
        isSequenceCorrect: Bool = true
    ) -> TimeLine {
        let now = Date()
        let timeline = TimeLine(

            id: id,
            title: title,
            timeLineIndex: timeLineIndex,
            occurredTime: occurredTime,
            isSequenceCorrect: isSequenceCorrect,
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

    /// 커밋(작성 완료) 처리.
    @discardableResult
    func commit(id: UUID) -> Bool {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let trimmedEmpty = timelines[idx].title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        guard !trimmedEmpty else { return false }
        timelines[idx].updatedAt = Date()
        scheduleSave()
        return true
    }

    /// 삭제
    func deleteTimeline(id: UUID) {
        guard let idx = timelines.firstIndex(where: { $0.id == id }) else {
            return
        }
        timelines.remove(at: idx)
        scheduleSave()
    }
}
