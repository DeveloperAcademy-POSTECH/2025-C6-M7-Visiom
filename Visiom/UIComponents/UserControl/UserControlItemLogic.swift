//
//  UserControlItemLogic.swift
//  Visiom
//
//  Created by Elphie on 11/3/25.
//

import Foundation

// 버튼 로직
struct UserControlItemLogic {

    static func isEnabled(_ item: UserControlItem, when state: InteractionState)
        -> Bool
    {
        // visibility : 배치 불가
        if case .visibility = state {
            switch item {
            case .visibility:
                return true
            case .photoCollection, .memo, .timeline:
                return false
            default:
                return true
            }
        }

        // idle: 전부 가능
        return true
    }

    static func apply(_ item: UserControlItem, from state: InteractionState)
        -> InteractionState
    {

        switch item {
        case .back:
            return .idle
            
        case .photoCollection, .memo, .teleport, .placedImage:
            // 배치 시작/해제
            if case .placing(let t) = state, t == item {
                return .idle
            } else {
                return .placing(item)
            }

        case .timeline:
            return state == .timeline ? .idle : .timeline

        case .visibility:
            return state == .visibility ? .idle : .visibility

        case .cameraheight:
            return state == .cameraheight ? .idle : .cameraheight
        
        case .miniMap:
            return state == .miniMap ? .idle : .miniMap
        }
    }
}
