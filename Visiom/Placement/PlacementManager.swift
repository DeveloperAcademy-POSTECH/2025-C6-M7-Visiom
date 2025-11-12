//
//  PlacementManager.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  앵커의 위치를 관리해줌
//  앵커의 이동, 삭제, 생성을 데이터로 관리
//

import Foundation
import RealityKit
import simd

@MainActor
public final class PlacementManager {
    private let anchorRegistry: AnchorRegistry
    private let sceneRoot: Entity
    
    public var onMoved: ((AnchorRecord) -> Void)?
    public var onRemoved: ((UUID) -> Void)?
    
    public init(anchorRegistry: AnchorRegistry, sceneRoot: Entity) {
        self.anchorRegistry = anchorRegistry
        self.sceneRoot = sceneRoot
    }
    
    // 사용자 전방 1m에 월드 앵커 생성 후 Registry 기록
    public func place(kind: EntityKind, dataRef: UUID? = nil,
                      forwardFrom cameraTransform: simd_float4x4) -> UUID {
        let anchorID = UUID()
        var t = matrix_identity_float4x4
        // 카메라 forward -Z 로 1m 전방
        t = cameraTransform
        t.columns.3 += simd_float4(0, 0, -1, 0) // 1m 전방
        
        let rec = AnchorRecord(id: anchorID,
                               kind: kind.rawValue,
                               dataRef: dataRef,
                               transform: t)
        anchorRegistry.upsert(rec)
        return anchorID
    }
    
    // 드래그에 따른 앵커 transform 갱신
    public func moveAnchor(anchorID: UUID, deltaWorld: SIMD3<Float>) {
        guard var rec = anchorRegistry.records[anchorID] else { return }
        
        // ⚙️ y 이동 방지: teleport만 y=0 고정
        if let kind = EntityKind(rawValue: rec.kind), kind == .teleport {
            rec.worldMatrix.columns.3.x += deltaWorld.x
            rec.worldMatrix.columns.3.z += deltaWorld.z
            // y값은 고정
        } else {
            rec.worldMatrix.columns.3.x += deltaWorld.x
            rec.worldMatrix.columns.3.y += deltaWorld.y
            rec.worldMatrix.columns.3.z += deltaWorld.z
        }
        
        anchorRegistry.upsert(rec)
        onMoved?(rec)
    }
    
    public func removeAnchor(anchorID: UUID) {
        anchorRegistry.remove(anchorID)
        onRemoved?(anchorID)
    }
    
    private func applyTransform(_ rec: AnchorRecord, to entity: Entity){
        entity.transform.matrix = rec.worldMatrix
        entity.anchorID = rec.id
    }
}
