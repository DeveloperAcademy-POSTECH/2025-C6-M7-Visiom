////
////  Ext+FullImmersiveView.swift
////  Visiom
////
////  Created by 윤창현 on 10/31/25.
////
//
//import ARKit
//import RealityKit
//import SwiftUI
//
//// MARK: - Placement Extension
//extension FullImmersiveView {
//
//    func makePlacement(type: UserControlItem, dataRef: UUID? = nil) async {
//        // 현재 시간을 기준으로 기기의 포즈(위치와 방향)를 가져옴
//        let timestamp = CACurrentMediaTime()
//        guard
//            let deviceAnchor = Self.worldTracking.queryDeviceAnchor(
//                atTimestamp: timestamp
//            )
//        else {
//            // 기기 위치를 못 가져오면 일단 원점에라도 생성
//            // await createAnchor(at: matrix_identity_float4x4, for: type)
//            return
//        }
//
//        // 이 위치에 앵커 생성 요청
//        await createAnchor(
//            usingCamera: deviceAnchor.originFromAnchorTransform,
//            for: type,
//            dataRef: dataRef
//        )
//
//    }
//
//    func createAnchor(
//        usingCamera cameraTransform: simd_float4x4,
//        for type: UserControlItem,
//        dataRef: UUID? = nil
//    )
//        async
//    {
//        guard root != nil else { return }
//        guard let placementManager else {
//            print("⚠️ placementManager not ready")
//            return
//        }
//
//        // === 1) 카메라 앞 0.5m 위치를 '월드 좌표계'로 계산===
//        let devicePosition = SIMD3<Float>(
//            cameraTransform.columns.3.x,
//            cameraTransform.columns.3.y,
//            cameraTransform.columns.3.z
//        )
//        let deviceForwardVector = -SIMD3<Float>(
//            cameraTransform.columns.2.x,
//            cameraTransform.columns.2.y,
//            cameraTransform.columns.2.z
//        )
//        let flatForward = normalize(
//            SIMD3<Float>(deviceForwardVector.x, 0, deviceForwardVector.z)
//        )
//        let distance: Float = 0.5
//
//        let spawnPos: SIMD3<Float>
//        switch type {
//        case .teleport:
//            spawnPos = SIMD3<Float>(
//                devicePosition.x + flatForward.x * distance,
//                0,  // <- y=0 고정
//                devicePosition.z + flatForward.z * distance
//            )
//        case .memo, .photoCollection:
//            spawnPos = devicePosition + flatForward * distance
//        case .timeline:
//            let timelineDistance: Float = 1.5
//            spawnPos = devicePosition + flatForward * timelineDistance
//        default:
//            spawnPos = devicePosition + flatForward * distance
//        }
//                
//        let anchorID: UUID
//        switch type {
//        case .photoCollection:
//            anchorID = placementManager.place(
//                kind: .photoCollection,
//                dataRef: nil,
//                forwardFrom: cameraTransform
//            )
//            print("PhotoCollection Anchor 생성 완료")
//        case .memo:
//            anchorID = placementManager.place(
//                kind: .memo,
//                dataRef: nil,
//                forwardFrom: cameraTransform
//            )
//        case .teleport:
//            anchorID = placementManager.place(
//                kind: .teleport,
//                dataRef: nil,
//                forwardFrom: cameraTransform
//            )
//        case .timeline:
//            anchorID = placementManager.place(
//                kind: .timeline,
//                dataRef: dataRef,
//                forwardFrom: cameraTransform
//            )
//        default: fatalError("Unknown item type: \(type)")
//        }
//
//        guard var rec = anchorRegistry.records[anchorID] else {
//            print("⚠️ AnchorRecord not found for \(anchorID)")
//            return
//        }
//        
//        var t = Transform(matrix: rec.worldMatrix)
//        t.translation = spawnPos
//        rec.worldMatrix = t.matrix
//        anchorRegistry.upsert(rec)
//
//        do {
//            // 사용자 앞에 앵커 추가 (현재는 월드 원점에 아이덴티티 변환으로 배치)
//            let anchor = WorldAnchor(
//                originFromAnchorTransform: rec.worldMatrix
//            )
//            // 생성된 WorldAnchor를 worldTracking 프로바이더에 추가
//            try await Self.worldTracking.addAnchor(anchor)
//            switch type {
//            case .photoCollection:
//                // 1) Photo Collection 생성
//                let newCol = collectionStore.createCollection()
//                collectionStore.renameCollection(
//                    newCol.id,
//                    to: newCol.id.uuidString
//                )
//
//                // 2) 레코드에 dataRef 연결 후 upsert
//                var updated = rec
//                updated.dataRef = newCol.id
//                anchorRegistry.upsert(updated)
//
//                // 3) 즉시 스폰(런타임 표현) — 부트스트랩과 동일한 규약 사용
//                await spawnEntity(updated)
//                persistence?.save()
//                openWindow(
//                    id: appModel.photoCollectionWindowID,
//                    value: newCol.id
//                )
//            case .memo:
//                // 1) 생성한 Memo 정보 가져오기
//
//                guard let memoID: UUID = appModel.memoToAnchorID else { return }
//
//                // 2) 레코드에 dataRef 연결 후 upsert
//                var updated = rec
//                updated.dataRef = memoID
//                anchorRegistry.upsert(updated)
//
//                // 3) 즉시 스폰(런타임 표현) — 부트스트랩과 동일한 규약 사용
//                await spawnEntity(updated)
//
//                persistence?.save()
//
//            case .teleport:
//                // 1) 레코드에 dataRef 연결 후 upsert
//                let updated = rec
//                anchorRegistry.upsert(updated)
//
//                // 2) 즉시 스폰(런타임 표현) — 부트스트랩과 동일한 규약 사용
//                await spawnEntity(updated)
//
//                persistence?.save()
//
//            case .timeline:
//                let timelineID = dataRef ?? appModel.timelineToAnchorID
//                guard let timelineID else { return }
//
//                var updated = rec
//                updated.dataRef = timelineID
//                anchorRegistry.upsert(updated)
//
//                // 3) 즉시 스폰(런타임 표현) — 부트스트랩과 동일한 규약 사용
//                await spawnEntity(updated)
//                persistence?.save()
//
//            default:
//                break
//            }
//        } catch {
//            print("월드 앵커 추가 failed")
//        }
//    }
//
//    @MainActor
//    func spawnEntity(_ rec: AnchorRecord) async {
//        guard entityByAnchorID[rec.id] == nil else { return }
//        guard let kind = EntityKind(rawValue: rec.kind) else { return }
//
//        let parent: Entity = {
//            switch kind {
//            case .photoCollection: return (photoGroup ?? root)!
//            case .memo: return (memoGroup ?? root)!
//            case .teleport: return (root ?? Entity())
//            case .timeline: return (timelineGroup ?? root)!
//            }
//        }()
//
//        let entity: Entity
//        switch kind {
//        case .photoCollection:
//            guard let ref = rec.dataRef else { return }
//            entity = EntityFactory.makePhotoCollection(
//                anchorID: rec.id,
//                dataRef: ref
//            )
//        case .memo:
//            guard let ref = rec.dataRef else { return }
//            entity = EntityFactory.makeMemo(anchorID: rec.id, dataRef: ref)
//        case .teleport:
//            entity = EntityFactory.makeTeleport(anchorID: rec.id)
//        case .timeline:
//            guard let ref = rec.dataRef else { return }
//            entity = EntityFactory.makeTimeline(anchorID: rec.id, dataRef: ref)
//        }
//
//        await bootstrap?.attachVisual(for: kind, to: entity, record: rec)
//
//        // 3) transform/부모/맵 갱신
//        entity.transform.matrix = rec.worldMatrix
//        parent.addChild(entity)
//        entityByAnchorID[rec.id] = entity
//    }
//
//    func containerWithPolicy(from entity: Entity) -> Entity? {
//        var cur: Entity? = entity
//        while let e = cur {
//            if e.components.has(InteractionPolicyComponent.self) { return e }
//            cur = e.parent
//        }
//        return nil
//    }
//}
