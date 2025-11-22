//
//  InteractionPolicyComponent.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  Interaction 정책
//  1) Entity의 종류
//  2) Entity의 행동 권한
//  3) Entity의 충돌 그룹
//  4) 각 Entity에 부착되는 정책 정보
//  5) Entity 의 Interaction 관리
//

import Foundation
import RealityKit

// Entity의 종류 열거
public enum EntityKind: String, Codable, CaseIterable, Sendable {
    case memo, photoCollection, teleport, timeline
}

// Entity의 행동 권한
public struct Capabilities: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let place   = Capabilities(rawValue: 1 << 0)
    public static let persist = Capabilities(rawValue: 1 << 1)
    public static let delete  = Capabilities(rawValue: 1 << 2)
    public static let move    = Capabilities(rawValue: 1 << 3)
    public static let tap     = Capabilities(rawValue: 1 << 4)
}

// Entity 충돌 그룹
public extension CollisionGroup {
    // 사진 메모가 소속됨
    static let content  = CollisionGroup(rawValue: 1 << 0)
    // 텔레포트가 소속됨
    static let teleport = CollisionGroup(rawValue: 1 << 1)
}

public struct InteractionPolicyComponent: Component, Sendable {
    // Entity에 부착되는 정책 정보
    // 어떤 종류의 entity인지, 어떤 권한이 있는지, 어떤 그룹에 속하는지, 외부 데이터와 연결되는지
    // Q. 왜 Entity에 정책을 부착하는가?
    // A. 런타임에 부착된 정책만 읽어 의미 결정
    //    -> 타임캐스팅/if 체인을 제거
    public var kind: EntityKind
    public var caps: Capabilities
    public var collisionGroup: CollisionGroup
    public var dataRef: UUID?

    public init(kind: EntityKind,
                caps: Capabilities,
                collisionGroup: CollisionGroup,
                dataRef: UUID? = nil) {
        self.kind = kind
        self.caps = caps
        self.collisionGroup = collisionGroup
        self.dataRef = dataRef
    }
}

// Dependency Injection 번들
public struct InteractionContext {
    // 배치,이동,삭제 등 Entity의 공간적 생명주기 관리
    public let placement: PlacementManager
    
    // 저장, 불러오기 담당
    public let persistence: PersistenceManager
    
    // 창 열기
    public let openWindow: (String) -> Void
    
    // 창 닫기
    public let dismissWindow: (String) -> Void
    
    // 텔레포트
    public let teleportToID: (UUID) -> Void
}
