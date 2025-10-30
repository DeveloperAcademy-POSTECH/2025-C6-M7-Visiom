//
//  MarkerVisibilityManager.swift
//  Visiom
//
//  Created by 윤창현 on 10/30/25.
//

import SwiftUI
import Combine

@MainActor
final class MarkerVisibilityManager: ObservableObject {
    static let shared = MarkerVisibilityManager()
    @Published var isVisible: Bool = true
}
