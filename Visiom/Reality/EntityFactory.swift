//
//  EntityFactory.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
// Entity 표준 규격화
// Entity 생성에 대한 기준을 정하고 강제합니다
// 이 파일이 변경될 때는 반드시 변경사항이 공유가 되어야합니다.
//

import Foundation
import RealityKit


public enum EntityFactory {
    
    // 3D 화면을 그리면서 applyCollisionFilter함수가 반복적으로 호출됨
    // 따라서 오버헤드 발생 가능성 있음
    // 그러므로 inline으로 처리
    @inline(__always)
    private static func applyCollisionFilter(_ e: Entity,
                                             group: CollisionGroup,
                                             mask: CollisionGroup) {
        e.generateCollisionShapes(recursive: true)
        
        if var cc = e.components[CollisionComponent.self] {
            // 이미 CollisionComponent 가 있다면
            // 충돌 규칙만 적용
            cc.filter = CollisionFilter(group: group, mask: mask)
            // 규칙 적용 갱신
            e.components[CollisionComponent.self] = cc
        } else {
            // 아직도 없다면 기본 shape 하나를 붙여서 컴포넌트 생성
            let shape = ShapeResource.generateBox(size: .init(0.1, 0.1, 0.1))
            // CollisionComponent 생성, 충돌 규직 적용
            let cc = CollisionComponent(
                shapes: [shape],
                mode: .default,
                filter: CollisionFilter(group: group, mask: mask)
            )
            e.components.set(cc)
        }
    }
    
    public static func makePhotoCollection(anchorID: UUID, dataRef: UUID) -> Entity {
        let e = Entity()
        e.name = anchorID.uuidString        // entity 식별을 위해 앵커 id를 공유
        e.components.set(InteractionPolicyComponent(
            kind: .photoCollection,
            // photoCollection entity가 허용하는 상호작용
            caps: [.place, .persist, .delete, .move, .tap],
            collisionGroup: .content,
            dataRef: dataRef
        ))
        applyCollisionFilter(e, group: .content, mask: [.content])
        
        return e
    }
    
    public static func makeMemo(anchorID: UUID, dataRef: UUID) -> Entity {
        let e = Entity()
        e.name = anchorID.uuidString        // entity 식별을 위해 앵커 id를 공유
        e.components.set(InteractionPolicyComponent(
            kind: .memo,
            // memo entity 가 허용하는 상호작용
            caps: [.place, .persist, .delete, .move, .tap],
            collisionGroup: .content,
            dataRef: dataRef
        ))
        applyCollisionFilter(e, group: .content, mask: [.content])
        return e
    }

    public static func makeTeleport(anchorID: UUID) -> Entity {
        let e = Entity()
        e.name = anchorID.uuidString       // entity 식별을 위해 앵커 id를 공유
        e.components.set(InteractionPolicyComponent(
            kind: .teleport,
            // teleport entity가 허용하는 상호작용
            caps: [.place, .persist, .delete, .move, .tap],
            collisionGroup: .teleport,
            dataRef: nil
        ))
        applyCollisionFilter(e, group: .teleport, mask: [.teleport])
        return e
    }
}
