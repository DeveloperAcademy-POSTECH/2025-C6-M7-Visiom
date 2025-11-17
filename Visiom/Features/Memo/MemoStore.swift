//
//  MemoStore.swift
//  Visiom
//
//  Created by Elphie on 10/30/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class MemoStore {
    private let persistence = PersistenceActor()
    var memos: [Memo] = []
    var memoToAnchorID: UUID? = nil
    
    init() {
        Task { await load() }
    }
    
    func load() async {
        do {
            let url = try FileLocations.memosIndexFile()
            let decoded: [Memo] = try await persistence.load(from: url)
            self.memos = decoded
        } catch {
            print("Load memos error:", error)
            self.memos = []
        }
    }
    
    // MARK: - Save batching
    private func scheduleSave() {
        let snapshot = self.memos
                guard let url = try? FileLocations.memosIndexFile() else { return }
                Task {
                    await persistence.enqueueWrite(snapshot, to: url)
                }
    }
    
    func flushSaves() async {
        await persistence.flush()
    }
    
    // MARK: - Query
    func memo(id: UUID) -> Memo? {
        memos.first(where: { $0.id == id })
    }
    
    // MARK: - CRUD
    @discardableResult
    func createMemo(id: UUID = UUID(), initialText: String = "") -> Memo {
        let now = Date()
        let memo = Memo(id: id,
                         text: initialText,
                         createdAt: now,
                         updatedAt: now,
                         status: .draft)
        memos.insert(memo, at: 0)
        scheduleSave()
        return memo
    }
    
    /// 텍스트 변경
    func updateText(id: UUID, to newText: String) {
        guard let idx = memos.firstIndex(where: { $0.id == id }) else { return }
        memos[idx].text = newText
        memos[idx].updatedAt = Date()
        scheduleSave()
    }
    
    /// 커밋(작성 완료) 처리.
    @discardableResult
    func commit(id: UUID) -> Bool {
        guard let idx = memos.firstIndex(where: { $0.id == id }) else { return false }
        let trimmedEmpty = memos[idx].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard !trimmedEmpty else { return false }
        memos[idx].status = .committed
        memos[idx].updatedAt = Date()
        scheduleSave()
        return true
    }
    
    /// 삭제
    func deleteMemo(id: UUID) {
        guard let idx = memos.firstIndex(where: { $0.id == id }) else { return }
        memos.remove(at: idx)
        scheduleSave()
    }
}
