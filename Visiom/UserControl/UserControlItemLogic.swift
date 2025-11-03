//
//  UserControlItemLogic.swift
//  Visiom
//
//  Created by Elphie on 11/3/25.
//

import Foundation

// 버튼 로직
struct UserControlItemLogic {
    
    static func isEnabled(_ item: UserControlItem, when state: InteractionState) -> Bool {
        // 뒤로가기 : 항상 가능
        if item == .back { return true }
        
        // 배치 중 : 다른 기능 불가
        if case let .placing(active) = state {
            switch item {
            case active:
                return true
            case .back:
                return true
            default :
                return false
            }
        }
        
        // 드로잉 중 : 다른 기능 불가
        if state == .drawing {
            switch item {
            case .drawing:
                return true
            case .back:
                return true
            default :
                return false
            }
        }
        
        // 이동 모드 : 모든 기능 사용 가능
        if state == .moving {
            switch item {
            default:
                return true
            }
        }
        
        // 보드 : 배치 불가
        if state == .board {
            switch item {
            case .board:
                return true
            case .visibility, .moving, .back:
                return true
            default:
                return false
            }
        }
        
        // visibility : 배치 불가
        if case .visibility = state {
            switch item {
            case .visibility:
                return true
            case .moving, .board, .back:
                return true
            default:
                return false
            }
        }
        
        // idle: 전부 가능
        return true
    }
    
    static func apply(_ item: UserControlItem, from state: InteractionState) -> InteractionState {
        
        switch item {
        case .back:
            return .idle
            
        case .photo, .memo, .number, .sticker, .mannequin:
            // 배치 시작/해제
            if case .placing(let t) = state, t == item {
                return .idle
            } else {
                return .placing(item)
            }
            
        case .drawing:
            return state == .drawing ? .idle : .drawing
            
        case .moving:
            return state == .moving ? .idle : .moving
            
        case .board:
            return state == .board ? .idle : .board
            
        case .visibility:
            return state == .visibility ? .idle : .visibility
        }
    }
}
