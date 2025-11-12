//
//  SwiftUIInputSurface.swift
//  Visiom
//
//  Created by Elphie on 11/9/25.
//

import Foundation
import RealityKit
import SwiftUI

@MainActor
final class SwiftUIInputSurface: InputSurface {
    // 프로토콜 요구 콜백
    var onTap: ((_ screenLocation: CGPoint, _ worldPos: SIMD3<Float>) -> Void)?
    var onLongPress: ((_ screenLocation: CGPoint) -> Void)?
    var onDrag: ((_ startScreenLocation: CGPoint, _ deltaWorld: SIMD3<Float>, _ phase : GesturePhase) -> Void)?
    
    // Targeted 제스처에서 얻은 마지막 히트 엔티티를 캐시
    // (SwiftUI에서 정확한 screenLocation을 얻기 어려워 대체)
    private var lastHitEntity: Entity? = nil
    private var dragStartScreen: CGPoint? = nil
    
    
    // ⬇️ 드래그용 캐시 추가
    private var lastDragWorld: SIMD3<Float>? = nil
    
    // 뷰에서 쓸 setter 제공
    func setLastHitEntity(_ e: Entity?) { self.lastHitEntity = e }
    func setDragStartScreen(_ p: CGPoint?) { self.dragStartScreen = p }
    
    /// 드래그 단계별 헬퍼 — 현재 월드 좌표만 넘기면 내부에서 델타를 계산해 onDrag 호출
    func beginDrag(currentWorld: SIMD3<Float>) {
        lastDragWorld = currentWorld
        onDrag?(.zero, .zero, .began)
    }
    func updateDrag(currentWorld: SIMD3<Float>) {
        if let prev = lastDragWorld {
            onDrag?(.zero, currentWorld - prev, .changed)
        } else {
            onDrag?(.zero, .zero, .changed)
        }
        lastDragWorld = currentWorld
    }
    func endDrag() {
        onDrag?(.zero, .zero, .ended)
        lastDragWorld = nil
        lastHitEntity = nil
        dragStartScreen = nil
    }
    
    
    /// 마스크 기반 레이캐스트 결과로 "최상위 Entity" 반환
    func raycast(from screenLocation: CGPoint, mask: CollisionGroup) -> Entity? {
        // SwiftUI Targeted 제스처를 통해 이미 hit entity를 갖고 있는 경우만 처리
        guard let hit = lastHitEntity else { return nil }
        var cur: Entity? = hit
        while let node = cur {
            if node.components.has(InteractionPolicyComponent.self){ return node }
            cur = node.parent
        }
        
        return hit
    }
    
    func pushDragSample(currentWorld: SIMD3<Float>?, isEnded: Bool) {
        if isEnded {
            onDrag?(.zero, .zero, .ended)
            lastDragWorld = nil
            lastHitEntity = nil
            dragStartScreen = nil
            return
        }
        guard let cur = currentWorld else { return }
        if let prev = lastDragWorld {
            onDrag?(.zero, cur - prev, .changed)
        } else {
            onDrag?(.zero, .zero, .began)
        }
        lastDragWorld = cur
    }
}
