//
//  AnchorRecord.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
// 엔티티를 저장/복원하기 위한 역할.
// Codable 로 디스크 입출력(JSON 등) 가능
// Identifiable 로 UI/리스트 연동
// Sendable 로 스레드 간 전달 안정성 확보
//

import RealityKit
import Foundation

public struct AnchorRecord: Codable, Identifiable, Sendable {
    public var id: UUID         // 앵커 식별자
    public var kind: String     // Entity의 종류 (예: photoCollection, memo, teleport)
    public var dataRef: UUID?   // 이 Entity가 참조하는 데이터의 ID (메모 내용, collection)
    public var worldMatrix: simd_float4x4     // 최종 변환 위치
    public var kindEnum : EntityKind?
    
    public init(id: UUID, kind: String, dataRef: UUID?, transform: simd_float4x4) {
        self.id = id
        self.kind = kind
        self.dataRef = dataRef
        self.worldMatrix = transform
        self.kindEnum = EntityKind(rawValue: kind)
    }
    
    // JSON 필드명을 명시한 것
    private enum CodingKeys: String, CodingKey { case id, kind, dataRef, matrix }
    
    // 디스크 -> 메모리 복원
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decode(String.self, forKey: .kind)
        dataRef = try c.decodeIfPresent(UUID.self, forKey: .dataRef) // decodeIfPresent은 optional 처리
        
        let flat = try c.decode([Float].self, forKey: .matrix)
        // 16개가 맞는지 확인. 4x4 행렬 값이 모두 없으면 데이터 손상
        guard flat.count == 16 else { throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.matrix], debugDescription: "matrix must have 16 floats")) }
        // 16개 float 값을 simd_4x4 로 재조립
        worldMatrix = AnchorRecord.makeMatrix(from: flat)
    }
    
    // 메모리 -> 디스크 저장
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encodeIfPresent(dataRef, forKey: .dataRef)
        // 4x4 행렬을 16개의 float 값으로 변경 후 기록
        try c.encode(AnchorRecord.flatten(matrix: worldMatrix), forKey: .matrix)
    }
    
    // 4x4 행렬을 16개의 float 값으로 변경
    private static func flatten(matrix m: simd_float4x4) -> [Float] {
        [ m.columns.0.x, m.columns.0.y, m.columns.0.z, m.columns.0.w,
          m.columns.1.x, m.columns.1.y, m.columns.1.z, m.columns.1.w,
          m.columns.2.x, m.columns.2.y, m.columns.2.z, m.columns.2.w,
          m.columns.3.x, m.columns.3.y, m.columns.3.z, m.columns.3.w ]
    }
    
    // 16개의 float 값을 4x4 행렬로 재조립
    private static func makeMatrix(from a: [Float]) -> simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(a[0],  a[1],  a[2],  a[3]),
            SIMD4<Float>(a[4],  a[5],  a[6],  a[7]),
            SIMD4<Float>(a[8],  a[9],  a[10], a[11]),
            SIMD4<Float>(a[12], a[13], a[14], a[15])
        )
    }
}
