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
    // 내부 영속 큐
    private let persistence = PersistenceActor()

    // 전체 메모 목록 (단일 소스)
    var memos: [Memo] = []

    // MARK: - Init / Load
    init() {
        Task { await load() }
    }

    func load() async {
        // 추후 구현
    }

    // MARK: - Save batching
    private func scheduleSave() {
        // 추후 구현
    }

    // 필요시 강제 flush (앱 종료 전 등)
    func flushSaves() async {
        // 추후 구현
    }

    // MARK: - Query
    func memo(id: UUID) -> Memo? {
        memos.first(where: { $0.id == id })
    }

    // MARK: - CRUD
    /// 신규 draft 생성 (id를 외부에서 만들었으면 주입 가능)
    @discardableResult
    func createDraft(id: UUID = UUID(), initialText: String = "") -> Memo {
        let now = Date()
        let draft = Memo(id: id,
                         text: initialText,
                         createdAt: now,
                         updatedAt: now,
                         status: .draft)
        memos.insert(draft, at: 0)
        scheduleSave()
        return draft
    }

    /// 텍스트 변경 (draft/committed 무관하게 수정 가능)
    func updateText(id: UUID, to newText: String) {
        guard let idx = memos.firstIndex(where: { $0.id == id }) else { return }
        memos[idx].text = newText
        memos[idx].updatedAt = Date()
        scheduleSave()
    }

    /// 커밋(작성 완료) 처리. 비어있으면 커밋하지 않음(정책에 맞게 바꿔도 됨)
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

    /// 보관 처리(선택 사항)
    func archive(id: UUID) {
        guard let idx = memos.firstIndex(where: { $0.id == id }) else { return }
        memos[idx].status = .archived
        memos[idx].updatedAt = Date()
        scheduleSave()
    }

    /// 삭제
    func delete(id: UUID) {
        guard let idx = memos.firstIndex(where: { $0.id == id }) else { return }
        memos.remove(at: idx)
        scheduleSave()
    }
}
