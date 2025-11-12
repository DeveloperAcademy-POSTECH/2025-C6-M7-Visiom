//
//  InteractionRouter.swift
//  Visiom
//
//  Created by Elphie on 11/4/25.
//
//  역할
//  탭, 드래그, 길게 누르기 제스처를 수신한다
//  수신한 제스처를 우선순위에 따라 처리한다.

import Foundation
import RealityKit

// 제스처의 생명주기
public enum GesturePhase {
    case began
    case changed
    case ended
    case cancelled
}

// 라우터가 이해하는 표준 이벤트 포멧
public enum GestureEvent {
    // tap : 선택한 Entity와 3D의 위치
    case tap(entity: Entity, location3D: SIMD3<Float>)
    
    // drag : 선택한 Entity와 이동량
    case drag(entity: Entity, deltaWorld: SIMD3<Float>, phase: GesturePhase)
    
    // longPress : 선택한 Entity
    case longPress(entity: Entity)
}

public struct RoutingRule {
    public let mask: CollisionGroup
    public let handler: @MainActor (Entity, GestureEvent, InteractionContext) -> Bool
    
    public init(mask: CollisionGroup,
                handler: @escaping @MainActor (Entity, GestureEvent, InteractionContext) -> Bool) {
        self.mask = mask
        self.handler = handler
    }
}

@MainActor
public final class InteractionRouter {
    // InteractionContext : 모든 처리에 필요한 Dependency Injection 번들
    private let ctx: InteractionContext
    
    public init(context: InteractionContext) {
        self.ctx = context
    }
    
    // 속한 그룹(mask)에 따라 다른 handler 적용
    // 배열의 순서대로 우선순위 부여
    private lazy var rules: [RoutingRule] = [
        .init(mask: .content,  handler: handleContent),
        .init(mask: .teleport, handler: handleTeleport)
    ]
    
    // 파일 상단 private 유틸로 추가
    private func policyContainer(from e: Entity) -> Entity {
        var cur: Entity? = e
        while let node = cur {
            if node.components.has(InteractionPolicyComponent.self) { return node }
            cur = node.parent
        }
        return e
    }
    
    public func route(hitEntity: Entity?, event: GestureEvent) {
        guard let entity = hitEntity else { return }
        let container = policyContainer(from: entity)
        
        let filter = entity.components[CollisionComponent.self]?.filter
        
        // Content > Teleport 우선순위 (rules 순서로 보장)
        for rule in rules {
            if let f = filter {
                if f.group.contains(rule.mask), rule.handler(entity, event, ctx) { return }
            } else {
                // 필터가 없으면 정책 쪽에서 그룹 검증하도록 그냥 시도
                if rule.handler(entity, event, ctx) { return }
            }
        }
    }
    
    private func handleContent(entity: Entity, event: GestureEvent, _ ctx: InteractionContext) -> Bool {
        let container = policyContainer(from: entity)
        // Entity가 소유하고 있는 정책이 content용이 맞는지 확인하기
        guard let pol: InteractionPolicyComponent = container.components[InteractionPolicyComponent.self],
              pol.collisionGroup == .content else { return false }
        
        // 제스처 처리하기
        switch event {
        case .tap(_, _):
            // 정책 기준, Entity가 tap 처리 정책을 가지고 있는가?
            guard pol.caps.contains(.tap) else { return false }
            
            switch pol.kind {
            case .photoCollection:
                if let id = pol.dataRef {
                    ctx.openWindow("PhotoCollectionWindowID:\(id.uuidString)")
                }
                return true
            case .memo:
                if let id = pol.dataRef {
                    ctx.openWindow("MemoEditWindowID:\(id.uuidString)")
                }
                return true
            case .teleport:
                return false  // content 핸들러가 teleport는 다루지 않음
            }
            
        case .drag(let e, let delta, let phase):
            // 정책 기준, Entity가 drag 처리 정책을 가지고 있는가?
            guard pol.caps.contains(.move) else { return false }
            guard let aID = container.anchorID else { return false }
            switch phase {
            case .began:
                return true
            case .changed:
                ctx.placement.moveAnchor(anchorID: aID, deltaWorld: delta)
                return true
            case .ended, .cancelled:
                if pol.caps.contains(.persist) { ctx.persistence.save() }
                return true
            }
            
            
        case .longPress(let e):
            // 정책 기준, Entity가 longPress 처리 정책을 가지고 있는가?
            guard pol.caps.contains(.delete) else { return false }
            
            // 모든 경우에 대해서 삭제처리를 하므로, 분기처리 불필요
            if let aID = e.anchorID {
                ctx.placement.removeAnchor(anchorID: aID)
                if pol.caps.contains(.persist) { ctx.persistence.save() }
                container.removeFromParent()
                return true
            }
            return false
        }
    }
    
    
    private func handleTeleport(entity: Entity, event: GestureEvent, _ ctx: InteractionContext) -> Bool {
        let container = policyContainer(from: entity)
        // Entity가 소유하고 있는 정책이 teleport용이 맞는지 확인하기
        guard let pol: InteractionPolicyComponent = container.components[InteractionPolicyComponent.self],
              pol.collisionGroup == .teleport else { return false }
        
        switch event {
        case .tap(_, _):
            // 텔레포트 해야한다고 알림
            NotificationCenter.default.post(name: .didRequestTeleport, object: entity)
            return true
            
        case .drag(let e, var delta, let phase):
            delta.y = 0
            guard let aID = e.anchorID else { return false }
            switch phase {
            case .began:
                return true
            case .changed:
                ctx.placement.moveAnchor(anchorID: aID, deltaWorld: delta)
                return true
            case .ended, .cancelled:
                if pol.caps.contains(.persist) { ctx.persistence.save() }
                return true
            }
            
        case .longPress:
            guard pol.caps.contains(.delete) else { return false }
            
            // 모든 경우에 대해서 삭제처리를 하므로, 분기처리 불필요
            if let aID = container.anchorID {
                ctx.placement.removeAnchor(anchorID: aID)
                if pol.caps.contains(.persist) { ctx.persistence.save() }
                container.removeFromParent()
                return true
            }
            return false
        }
    }
}

// 앵커 ID를 보유하는 엔티티에 부여할 얇은 프로토콜
public protocol SpatialAnchorCarrier {
    var anchorID: UUID? { get set }
}

extension Entity: SpatialAnchorCarrier {
    public var anchorID: UUID? {
        get { UUID(uuidString: self.name) }
        set { self.name = newValue?.uuidString ?? "" }
    }
}
