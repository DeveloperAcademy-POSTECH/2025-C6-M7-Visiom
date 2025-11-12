//
//  SpatialInteractable.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  Entity의 동작을 묶은 프로토콜

import RealityKit
import Foundation

public protocol SpatialInteractable {
    var policy: InteractionPolicyComponent? { get }     // Entity의 동작
    var anchorID: UUID? { get set }                     // Entity의 Anchor 데이터와 연결 ID
    var dataRef: UUID? { get set }                      // Entity가 참조하는 데이터와 연결 ID

    func onTap(ctx: InteractionContext)
    func onDrag(ctx: InteractionContext, deltaWorld: SIMD3<Float>)
    func onDelete(ctx: InteractionContext)
}

public extension SpatialInteractable where Self: Entity {
    var policy: InteractionPolicyComponent? {
        components[InteractionPolicyComponent.self]
    }
    var dataRef: UUID? {
        get { components[InteractionPolicyComponent.self]?.dataRef }
        set {
            if var p = components[InteractionPolicyComponent.self] {
                p.dataRef = newValue
                components[InteractionPolicyComponent.self] = p
            }
        }
    }
}
