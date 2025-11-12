//
//  AnchorRegistry.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  AnchorRecord의 컬렉션을 보관/갱신하는 저장소
//

import Foundation
import simd

@MainActor
public final class AnchorRegistry {
    // 모든 AnchorRecord를 담는 역할
    // AnchorRecode.id를 key 값으로, AnchorRecord를 value로
    // private 이므로 반드시 함수를 통해서 쓰거나 지울것
    private(set) var records: [UUID: AnchorRecord] = [:]
    
    public init() {}
    
    // 존재하면 덮어쓰기
    // 없으면 추가하기
    public func upsert(_ rec: AnchorRecord) {
        records[rec.id] = rec
    }
    
    // 삭제
    public func remove(_ id: UUID) {
        records.removeValue(forKey: id)
    }
    
    // 모든 레코드를 배열로 변환
    public func all() -> [AnchorRecord] { Array(records.values)
    }
    
    public func get(_ id: UUID) -> AnchorRecord? {
        records[id]
    }
    
    public func contains(_ id: UUID) -> Bool {
        records[id] != nil
    }
}
