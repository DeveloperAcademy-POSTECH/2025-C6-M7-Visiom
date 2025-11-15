//
//  Timeline.swift
//  Visiom
//
//  Created by jiwon on 11/14/25.
//

import Foundation

public struct Timeline: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var timelineIndex: Int
    public var occurredTime: Date?  // 사건 발생 시간
    public var isSequenceCorrect: Bool  // 시간에 따른 동선 성립 여부
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "",
        timelineIndex: Int = 0,
        occurredTime: Date? = nil,
        isSequenceCorrect: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now,
    ) {
        self.id = id
        self.title = title
        self.timelineIndex = timelineIndex
        self.occurredTime = occurredTime
        self.isSequenceCorrect = isSequenceCorrect
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
