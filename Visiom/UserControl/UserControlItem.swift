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
    case photo
    case memo
    case number
    case sticker
    case mannequin
    case drawing
    case visibility
    case board
    case moving
    
    // 기본 icon
    var icon: String {
        switch self {
        case .back:       return "arrow.uturn.left"
        case .photo:      return "photo"
        case .memo:       return "rectangle.badge.plus"
        case .number:     return "numbers"
        case .sticker:    return "plus.circle"
        case .mannequin:  return "figure"
        case .drawing:    return "pencil.and.scribble"
        case .visibility: return "eye"
        case .board:      return "text.line.first.and.arrowtriangle.forward"
        case .moving:     return "figure.walk"
        }
    }
    
    // 선택 icon
    var selectedIcon: String {
        switch self {
        case .back:       return "arrow.uturn.left"
        case .photo:      return "photo.fill"
        case .memo:       return "rectangle.fill.badge.plus"
        case .number:     return "123.rectangle.fill"
        case .sticker:    return "plus.circle.fill"
        case .mannequin:  return "figure.stand.line.dotted.figure.stand"
        case .drawing:    return "pencil.and.scribble"
        case .visibility: return "eye.slash"
        case .board:      return "text.line.first.and.arrowtriangle.forward"
        case .moving:     return "figure.walk.motion"
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
    case placing(UserControlItem)            // 사진/메모/숫자/스티커/마네킹
    case drawing                  // 드로잉
    case moving                   // 이동
    case board                    //  보드
    case visibility    // visible/invisible
    
    var activeItem: UserControlItem? {
        switch self {
        case .placing(let t): return t
        case .drawing:        return .drawing
        case .moving:         return .moving
        case .board:          return .board
        case .visibility:     return .visibility
        case .idle:           return nil
        }
    }
    
    var isPlacing: Bool {
        if case .placing = self { return true }
        return false
    }
}
