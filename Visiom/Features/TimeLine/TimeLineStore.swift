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

    // 추후 구현 예정...
}
