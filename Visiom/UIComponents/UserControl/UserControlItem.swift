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
    case timeline
    case teleport
    case placedImage
    case cameraheight
    case miniMap

    // 기본 icon
    var icon: String {
        switch self {
        case .back: return "arrow.uturn.left"
        case .photoCollection: return "photo"
        case .memo: return "rectangle.badge.plus"
        case .visibility: return "eye"
        case .timeline:      return "text.line.first.and.arrowtriangle.forward"
        case .teleport:     return "figure.walk"
        case .placedImage: return ""
        case .cameraheight: return "ruler"
        case .miniMap: return "photo.artframe.circle"
        }
    }

    // 선택 icon
    var selectedIcon: String {
        switch self {
        case .back: return "arrow.uturn.left"
        case .photoCollection: return "photo.fill"
        case .memo: return "rectangle.fill.badge.plus"
        case .visibility: return "eye.slash"
        case .timeline:      return "text.line.first.and.arrowtriangle.forward"
        case .teleport:     return "figure.walk.motion"
        case .placedImage: return ""
        case .cameraheight: return "ruler"
        case .miniMap: return "photo.artframe.circle"
        }
    }

    // 상태 존재 여부
    var isStateful: Bool {
        switch self {
        case .back: return false
        default: return true
        }
    }
}

enum InteractionState: Equatable {
    case idle  // 기본
    case placing(UserControlItem)  // 사진/메모
    case teleport  // 이동
    case timeline  //  보드
    case visibility  // visible/invisible
    case miniMap  // 위에서 보기
    case cameraheight  // 키(시점) 조절

    var activeItem: UserControlItem? {
        switch self {
        case .placing(let t): return t
        case .teleport: return .teleport
        case .timeline: return .timeline
        case .visibility: return .visibility
        case .idle: return nil
        case .miniMap: return .miniMap
        case .cameraheight: return .cameraheight
        }
    }

    var isPlacing: Bool {
        if case .placing = self { return true }
        return false
    }
}
