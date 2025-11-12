//
//  Memo.swift
//  Visiom
//
//  Created by Elphie on 10/30/25.
//

import Foundation

public enum MemoStatus: String, Codable, Equatable {
    case draft // 편집 중 (에디터에서 열렸거나 임시 저장 상태)
    case committed // 작성 완료(확정)
    case archived  // 보관(선택: 목록에 숨김 등)
}

public struct Memo: Identifiable, Codable, Equatable {
    public let id: UUID
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date
    public var status: MemoStatus

    public init(
        id: UUID = UUID(),
        text: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        status: MemoStatus = .draft
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
    }

    /// 공백 제거 후 내용이 비었는지 빠른 판별
    public var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
