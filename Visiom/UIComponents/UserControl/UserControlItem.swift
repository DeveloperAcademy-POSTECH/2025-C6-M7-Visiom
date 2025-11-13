//
//  UserControlItem.swift
//  Visiom
//
//  Created by Elphie on 11/2/25.
//

import SwiftUI

// 버튼 Item 종류
enum UserControlItem: CaseIterable, Hashable {
    case back
    case photoCollection
    case memo
    case visibility
    case board
    case teleport
    case topView
    
    // 기본 icon
    var icon: String {
        switch self {
        case .back:       return "arrow.uturn.left"
        case .photoCollection:      return "photo"
        case .memo:       return "rectangle.badge.plus"
        case .visibility: return "eye"
        case .board:      return "text.line.first.and.arrowtriangle.forward"
        case .teleport:     return "figure.walk"
        case .topView:    return "photo.artframe.circle"
        }
    }
    
    // 선택 icon
    var selectedIcon: String {
        switch self {
        case .back:       return "arrow.uturn.left"
        case .photoCollection:      return "photo.fill"
        case .memo:       return "rectangle.fill.badge.plus"
        case .visibility: return "eye.slash"
        case .board:      return "text.line.first.and.arrowtriangle.forward"
        case .teleport:     return "figure.walk.motion"
        case .topView:    return "photo.artframe.circle"
        }
    }
    
    // 상태 존재 여부
    var isStateful: Bool {
        switch self {
        case .back: return false
        default:    return true
        }
    }
}

enum InteractionState: Equatable {
    case idle                     // 기본
    case placing(UserControlItem) // 사진/메모
    case teleport                   // 이동
    case board                    //  보드
    case visibility    // visible/invisible
    case topView // 위에서 보기
    
    var activeItem: UserControlItem? {
        switch self {
        case .placing(let t): return t
        case .teleport:         return .teleport
        case .board:          return .board
        case .visibility:     return .visibility
        case .idle:           return nil
        case .topView:        return .topView
        }
    }
    
    var isPlacing: Bool {
        if case .placing = self { return true }
        return false
    }
}
