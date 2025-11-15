//
//  Ext+MixedImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import SwiftUI

// MARK: - Placement Extension
extension MixedImmersiveView {
    
    // 카메라 포즈를 가져와서 실제 앵커 생성 함수로 넘기는 함수
    func makePlacement(type: UserControlItem) async {
        // 현재 시간을 기준으로 기기의 포즈(위치와 방향)를 가져옴
        let timestamp = CACurrentMediaTime()
        guard
            let deviceAnchor = Self.worldTracking.queryDeviceAnchor(
                atTimestamp: timestamp
            )
        else {
            // 기기 위치를 못 가져오면 일단 원점에라도 생성
            // await createAnchor(at: matrix_identity_float4x4, for: type)
            return
        }
        
        // 이 위치에 앵커 생성 요청
        await createAnchor(usingCamera: deviceAnchor.originFromAnchorTransform, for: type)
        
    }
    
    // 카메라 기준으로 앵커를 하나 만들고 WorldAnchor과 Entity를 스폰하는 오케스트레이터
    func createAnchor(usingCamera cameraTransform: simd_float4x4, for type: UserControlItem)
    async
    {
        //MARK: - (1)기초 체크
        /// root 가 존재하는지 확인
        guard root != nil else {
            print("⚠️ root not ready")
            return
        }
        /// placementManager이 존재하는지 확인
        guard let placementManager else {
            print("⚠️ placementManager not ready")
            return
        }
        
        //MARK: - (2)카메라 앞 위치 계산
        let spawnPos: SIMD3<Float> = computeSpawnPosition( cameraTransform: cameraTransform, type: type)

        //MARK: - (3)Placement Manager에 AnchorRecord 하나 생성 요청
        let anchorID: UUID
        switch type {
        case .photoCollection:
            anchorID = placementManager.place(kind: .photoCollection, dataRef: nil, forwardFrom: cameraTransform)
        case .memo:
            anchorID = placementManager.place(kind: .memo, dataRef: nil, forwardFrom: cameraTransform)
        case .teleport:
            anchorID = placementManager.place(kind: .teleport, dataRef: nil, forwardFrom: cameraTransform)
        default : fatalError("Unknown item type: \(type)")
        }
        
        guard var rec = anchorRegistry.records[anchorID] else {
            print("⚠️ AnchorRecord not found for \(anchorID)")
            return
        }
        
        //MARK: - (4)레코드 transform 수정
        var t = Transform(matrix: rec.worldMatrix)
        t.translation = spawnPos
        rec.worldMatrix = t.matrix
        
        anchorRegistry.upsert(rec)
        
        do {
            //MARK: - (5)ARKit WorldAnchor 추가
            try await addWorldAnchor(for: rec)
            
            //MARK: - (6)타입별 후처리 + Entity 스폰
            /// Entity 종류에 따라서 dataRef 연결/스폰/ persistence/ 윈도우 오픈을 처리
            await handlePlacement(for: type, record: rec)
        } catch {
            print("월드 앵커 추가 failed")
        }
    }
    
    @MainActor
    func spawnEntity(_ rec: AnchorRecord) async {
        guard entityByAnchorID[rec.id] == nil else { return }
        guard let kind = EntityKind(rawValue: rec.kind) else { return }
        
        let parent: Entity = {
            switch kind {
            case .photoCollection: return (photoGroup ?? root)!
            case .memo:            return (memoGroup ?? root)!
            case .teleport:        return (root ?? Entity())
            }
        }()
        
        let entity: Entity
        switch kind {
        case .photoCollection:
            guard let ref = rec.dataRef else { return }
            entity = EntityFactory.makePhotoCollection(anchorID: rec.id, dataRef: ref)
        case .memo:
            guard let ref = rec.dataRef else { return }
            entity = EntityFactory.makeMemo(anchorID: rec.id, dataRef: ref)
        case .teleport:
            entity = EntityFactory.makeTeleport(anchorID: rec.id)
        }
        
        
        
        await bootstrap?.attachVisual(for: kind, to: entity, record: rec)
        
        // 3) transform/부모/맵 갱신
        entity.transform.matrix = rec.worldMatrix
        parent.addChild(entity)
        entityByAnchorID[rec.id] = entity
    }
    
    /// 카메라 앞 0.5m 위치 계산
    func computeSpawnPosition(cameraTransform: simd_float4x4, type: UserControlItem) -> SIMD3<Float> {
        let devicePosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        let deviceForwardVector = -SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )
        let flatForward = normalize(SIMD3<Float>(deviceForwardVector.x, 0, deviceForwardVector.z))
        let distance: Float = 0.5
        
        switch type {
        case .teleport:
            return SIMD3<Float>(
                devicePosition.x + flatForward.x * distance,
                0, // y=0 고정
                devicePosition.z + flatForward.z * distance
            )
        case .memo, .photoCollection:
            return devicePosition + flatForward * distance
        default:
            return devicePosition + flatForward * distance
        }
    }
    
    /// ARKit WorldAnchor 에 실제 앵커를 추가
    func addWorldAnchor(for rec: AnchorRecord) async throws {
        let anchor = WorldAnchor(originFromAnchorTransform: rec.worldMatrix)
        try await Self.worldTracking.addAnchor(anchor)
    }
    
    /// entity 종류별로 dataRef 연결, 스폰, persistence, 윈도우 오픈까지 담당
    func handlePlacement(for type: UserControlItem,
                         record rec: AnchorRecord) async {
        switch type {
        case .photoCollection:
            await handlePhotoCollectionPlacement(record: rec)
            
        case .memo:
            await handleMemoPlacement(record: rec)
            
        case .teleport:
            await handleTeleportPlacement(record: rec)
            
        default:
            break
        }
    }
    
    func handlePhotoCollectionPlacement(record rec: AnchorRecord) async {
        let rec = rec
        
        // 1) Photo Collection 생성
        let newCol = collectionStore.createCollection()
        collectionStore.renameCollection(newCol.id, to: newCol.id.uuidString)
        
        // 2) dataRef 연결 후 upsert
        var updated = rec
        updated.dataRef = newCol.id
        anchorRegistry.upsert(updated)
        
        // 3) 엔티티 스폰
        await spawnEntity(updated)
        persistence?.save()
        
        // 4) UI 오픈
        openWindow(id: appModel.photoCollectionWindowID,
                   value: newCol.id)
    }
    
    func handleMemoPlacement(record rec: AnchorRecord) async {
        guard let memoID = appModel.memoToAnchorID else { return }
        
        var updated = rec
        updated.dataRef = memoID
        anchorRegistry.upsert(updated)
        
        await spawnEntity(updated)
        persistence?.save()
    }
    
    func handleTeleportPlacement(record rec: AnchorRecord) async {
        anchorRegistry.upsert(rec)
        await spawnEntity(rec)
        persistence?.save()
    }
}
