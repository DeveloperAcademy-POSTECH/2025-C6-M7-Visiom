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
    
    // 드래그 시작 시점의 앵커 위치 캐시
    private var dragStartPosition: [UUID: SIMD3<Float>] = [:]
    
    public init(anchorRegistry: AnchorRegistry, sceneRoot: Entity) {
        self.anchorRegistry = anchorRegistry
        self.sceneRoot = sceneRoot
    }
    
    func tapToTeleport(anchorID: UUID) {
        
        guard let rec = anchorRegistry.records[anchorID] else { return }
       
        let sceneContent = self.sceneRoot
        
        // Calculate the vector from the origin to the tapped position
        let vectorToTap = rec.worldMatrix.columns.3
        // Normalize the vector to get a direction from the origin to the tapped position
        let direction = normalize(vectorToTap)
        
        // Calculate the distance (or magnitude) between the origin and the tapped position
        let distance = length(vectorToTap)
        
        // Calculate the new position by inverting the direction multiplied by the distance
        let newPosition = -direction * distance
        
        // Update sceneOffset's X and Z components, leave Y as it is
        sceneContent.position.x = newPosition.x
        sceneContent.position.z = newPosition.z
    }
    
    // 사용자 전방 1m에 월드 앵커 생성 후 Registry 기록
    public func place(
        kind: EntityKind,
        dataRef: UUID? = nil,
        forwardFrom cameraTransform: simd_float4x4,     //추후 수정
        sceneRoot: Entity
    ) -> UUID {
        // 1) 임시 entity에 월드 trasform 적용
        let tempCamera = Entity()
        tempCamera.setTransformMatrix(cameraTransform, relativeTo: nil)
        
        // 2) sceneRoot 기준으로 변환
        let cameraInScene = tempCamera.transformMatrix(relativeTo: sceneRoot)
        var placementTransform = Transform(matrix: cameraInScene)
        
        // 3) 1m 전방
        let forwardVector = -normalize(
            SIMD3<Float>(
                placementTransform.matrix.columns.2.x,
                placementTransform.matrix.columns.2.y,
                placementTransform.matrix.columns.2.z
            )
        )
        placementTransform.translation = placementTransform.translation + forwardVector * 1.0
        
        let anchorID = UUID()
        let rec = AnchorRecord(
            id: anchorID,
            kind: kind.rawValue,
            dataRef: dataRef,
            transform: placementTransform.matrix
        )
        anchorRegistry.upsert(rec)
        return anchorID
    }
    
    public func beginMove(anchorID: UUID) {
        guard let anchorRecord = anchorRegistry.records[anchorID] else { return }
        let position = SIMD3<Float>(
            anchorRecord.worldMatrix.columns.3.x,
            anchorRecord.worldMatrix.columns.3.y,
            anchorRecord.worldMatrix.columns.3.z
        )
        dragStartPosition[anchorID] = position
    }
    
    public func endMove(anchorID: UUID) {
        dragStartPosition.removeValue(forKey: anchorID)
    }
    
    // 드래그에 따른 앵커 transform 갱신
    public func moveAnchor(anchorID: UUID, deltaWorld: SIMD3<Float>) {
        guard var anchorRecord = anchorRegistry.records[anchorID] else { return }
        
        if let dragStartPosition = dragStartPosition[anchorID] {
            var newPosition = dragStartPosition + deltaWorld
            if let kind = EntityKind(rawValue: anchorRecord.kind), kind == .teleport {
                // 텔레포트는 y 고정
                newPosition.y = anchorRecord.worldMatrix.columns.3.y
            }
            anchorRecord.worldMatrix.columns.3 = SIMD4<Float>(newPosition, 1.0)
        } else {
            if let kind = EntityKind(rawValue: anchorRecord.kind), kind == .teleport {
                anchorRecord.worldMatrix.columns.3.x += deltaWorld.x
                anchorRecord.worldMatrix.columns.3.z += deltaWorld.z
            } else {
                anchorRecord.worldMatrix.columns.3.x += deltaWorld.x
                anchorRecord.worldMatrix.columns.3.y += deltaWorld.y
                anchorRecord.worldMatrix.columns.3.z += deltaWorld.z
            }
        }

        anchorRegistry.upsert(anchorRecord)
        onMoved?(anchorRecord)
    }
    
    public func removeAnchor(anchorID: UUID) {
        anchorRegistry.remove(anchorID)
        onRemoved?(anchorID)
    }
}
