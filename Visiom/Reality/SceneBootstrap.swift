//
//  SceneBootstrap.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  앱 실행시 RealityKit에 실제 엔티티를 다시 불러와 붙이는 역할을 전담
//  AnchorRecord로부터 복원하고 초기화함

import Foundation
import RealityKit

@MainActor
public final class SceneBootstrap {

    private let sceneRoot: Entity  // 루트 엔티티
    private let anchorRegistry: AnchorRegistry  // 앵커 데이터 테이블
    private let persistence: PersistenceManager  // 디스크 입출력
    public var onSpawned: ((UUID, Entity) -> Void)?  // (anchorID, container)
    public var memoTextProvider: ((UUID) -> String?)?

    public init(
        sceneRoot: Entity,
        anchorRegistry: AnchorRegistry,
        persistence: PersistenceManager
    ) {
        self.sceneRoot = sceneRoot
        self.anchorRegistry = anchorRegistry
        self.persistence = persistence
    }

    private enum GroupName: String {
        case photoCollection = "PhotoGroup"
        case memo = "MemoGroup"
        case teleport = "TeleportGroup"
        case timeline = "TimelineGroup"
    }

    // 사용 안하는 중
    // 추후 visible/invisible에 적용하기
    private func groupEntity(for kind: EntityKind) -> Entity {
        let name: String
        switch kind {
        case .photoCollection: name = GroupName.photoCollection.rawValue
        case .memo: name = GroupName.memo.rawValue
        case .teleport: name = GroupName.teleport.rawValue
        case .timeline: name = GroupName.timeline.rawValue
        }
        if let found = sceneRoot.findEntity(named: name) {
            return found
        }
        let group = Entity()
        group.name = name
        sceneRoot.addChild(group)
        return group
    }

    /// 앱 시작 시 디스크에서 복원 & 스폰
    public func restoreAndSpawn() async {
        // JSON에 저장된 [AnchorRecord] 읽어오기
        let recs = persistence.load()

        // Entity 생성하기
        for anchorRecord in recs {
            // anchorID = rec.id, kind = rec.kind
            guard let kind = EntityKind(rawValue: anchorRecord.kind) else { continue }

            let entity: Entity?
            switch anchorRecord.kind {
            case "photoCollection":
                guard let ref = anchorRecord.dataRef else { continue }
                entity = EntityFactory.makePhotoCollection(
                    anchorID: anchorRecord.id,
                    dataRef: ref
                )
            case "memo":
                guard let ref = anchorRecord.dataRef else { continue }
                entity = EntityFactory.makeMemo(anchorID: anchorRecord.id, dataRef: ref)
            case "teleport":
                entity = EntityFactory.makeTeleport(anchorID: anchorRecord.id)
            case "timeline":
                guard let ref = anchorRecord.dataRef else { continue }
                entity = EntityFactory.makeTimeline(anchorID: anchorRecord.id, dataRef: ref)
            default:
                continue
            }

            guard let e = entity else { continue }

            // sceneRoot 기준
            anchorRecord.applyTransform(to: e, relativeTo: sceneRoot)
            
            // anchorID 세팅
            e.anchorID = anchorRecord.id

            // groupEntity에 child로 추가하기
            let parent = groupEntity(for: kind)
            parent.addChild(e)

            await attachVisual(for: kind, to: e, record: anchorRecord)

            // 복원된 컨테이너를 맵에 등록
            onSpawned?(anchorRecord.id, e)

            // 메모리 최신화
            anchorRegistry.upsert(anchorRecord)
        }
    }

    func attachVisual(
        for kind: EntityKind,
        to container: Entity,
        record rec: AnchorRecord
    ) async {

        let visual = await AREntityFactory.createEntity(for: kind)

        switch kind {
        case .photoCollection:
            container.addChild(visual)
            visual.generateCollisionShapes(recursive: true)
            visual.components.set(InputTargetComponent())
            
        case .memo:
            container.addChild(visual)
            visual.generateCollisionShapes(recursive: true)
            visual.components.set(InputTargetComponent())

            if let memoID = rec.dataRef,
                let text = memoTextProvider?(memoID),
                !text.isEmpty
            {
                let overlay = AREntityFactory.createMemoTextOverlay(text: text)
                container.addChild(overlay)

                overlay.setPosition(
                    [0, 0, ARConstants.Position.memoTextZOffset],
                    relativeTo: container
                )
            }

        case .teleport:
            container.addChild(visual)
            visual.generateCollisionShapes(recursive: true)
            visual.components.set(InputTargetComponent())

        case .timeline:
            container.addChild(visual)
            visual.generateCollisionShapes(recursive: true)
            visual.components.set(InputTargetComponent())
        }
    }
}
