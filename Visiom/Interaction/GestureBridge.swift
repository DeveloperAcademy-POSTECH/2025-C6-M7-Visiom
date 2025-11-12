//
//  GestureBridge.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  제스처가 발생했을 때
//  어떤 entity에 적용해야하는가?
//  어떤 제스처가 발생했는가?
//  위의 것을 판단해서 타겟 entity와 제스처를 Router에 전달한다.
//  참고1) 여기서는 제스처에 따른 동작을 처리하지 않는다
//  참고2) 연속된 제스처(드래그, 핀치, 회전)는 타켓 entity를 고정 처리한다.
//

import Foundation
import RealityKit
import SwiftUI
import simd

// UI 와 제스처 상호 작용이므로 mainActor
@MainActor
public final class GestureBridge {
    
    private let inputSurface: InputSurface
    private let router: InteractionRouter
    
    // 제스처 별 락된 타깃 (제스처 시작 시 확정 → 종료 시 해제)
    // 제스처 중에 잠시 참조하는 값이라 weak로 선언
    private weak var lockedDragTarget: Entity?
    
    // 어떤 Entity가 타겟인지 결정함
    // 결정에서 우선순위를 1) content, 2) teleport 로
    private func prioritizedHit(from screenLocation: CGPoint,
                                in surface: InputSurface) -> Entity? {
        // 1) content
        if let e = surface.raycast(from: screenLocation,
                                   mask: [.content]) { return e }
        // 2) teleport
        if let e = surface.raycast(from: screenLocation,
                                   mask: [.teleport]) { return e }
        return nil
    }
    
    public init(surface: InputSurface, router: InteractionRouter) {
        self.inputSurface = surface
        self.router = router
        install()
    }
    
    private func install() {
        // 제스처 콜백을 여기로 브릿지
        inputSurface.onTap = { [weak self] location, worldPos in
            guard let self else { return }
            // 어떤 Entity를 타겟으로 할지?
            guard let hit = self.prioritizedHit(from: location, in: self.inputSurface) else {
                return
            }
            // router로 entity와 제스처 전달
            self.router.route(hitEntity: hit, event: .tap(entity: hit, location3D: worldPos))
        }
        
        inputSurface.onLongPress = { [weak self] location in
            guard let self else { return }
            guard let hit = self.prioritizedHit(from: location, in: self.inputSurface) else {
                return
            }
            self.router.route(hitEntity: hit, event: .longPress(entity: hit))
        }
        
        inputSurface.onDrag = { [weak self] startLoc, deltaWorld, phase in
            guard let self else { return }
            guard let target = self.lockedDragTarget ?? self.prioritizedHit(from: startLoc, in: self.inputSurface) else { return }
            switch phase {
            case .began:
                // 드래그 제스처가 시작 됐을때는
                // 어떤 Entity를 타겟으로 할지 정하고
                // 다른 Entity로 제스처가 옮겨가지 않도록 lock target으로 저장
                self.lockedDragTarget = self.prioritizedHit(from: startLoc, in: self.inputSurface)
            case .changed:
                // 타겟은 계속해서 처음에 지정했던 lock target으로 유지
                guard let target = self.lockedDragTarget else { return }
                self.router.route(hitEntity: target, event: .drag(entity: target, deltaWorld: deltaWorld, phase: .changed))
            case .ended, .cancelled:
                if let target = self.lockedDragTarget {
                    self.router.route(hitEntity: target, event: .drag(entity: target, deltaWorld: .zero, phase: .ended))
                }
                self.lockedDragTarget = nil
            }
        }
    }
}

public protocol InputSurface: AnyObject {
    var onTap: ((_ screenLocation: CGPoint, _ worldPos: SIMD3<Float>) -> Void)? { get set }
    var onLongPress: ((_ screenLocation: CGPoint) -> Void)? { get set }
    var onDrag: ((_ startScreenLocation: CGPoint, _ deltaWorld: SIMD3<Float>, _ phase : GesturePhase) -> Void)? { get set }
    
    /// 마스크 기반 레이캐스트 결과로 "최상위 Entity" 반환
    func raycast(from screenLocation: CGPoint, mask: CollisionGroup) -> Entity?
}
