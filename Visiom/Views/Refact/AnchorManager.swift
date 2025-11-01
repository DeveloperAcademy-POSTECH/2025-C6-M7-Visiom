//
//  AnchorManager.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import Combine

/// 앵커와 엔티티의 연관 데이터
struct AnchorData {
    let id: UUID
    var anchor: WorldAnchor
    var entity: Entity
    let itemType: UserControlBar
    var memoText: String = ""
    var collectionID: UUID? = nil
    
    mutating func update(with newAnchor: WorldAnchor) {
        self.anchor = newAnchor
    }
}

/// 앵커 관리 담당
@MainActor
class AnchorManager: NSObject, ObservableObject {
    @Published var anchorDataMap: [UUID: AnchorData] = [:]
    
    /// 새로운 앵커 데이터 추가
    func addAnchor(_ data: AnchorData) {
        anchorDataMap[data.id] = data
        debugLog("✅ Anchor added: \(data.id) (\(data.itemType))")
    }
    
    /// 앵커 데이터 업데이트
    func updateAnchor(id: UUID, anchor: WorldAnchor) throws {
        guard var data = anchorDataMap[id] else {
            throw ARError.anchorNotFound(id)
        }
        data.update(with: anchor)
        anchorDataMap[id] = data
        debugLog("🔄 Anchor updated: \(id)")
    }
    
    /// 앵커 제거
    func removeAnchor(id: UUID) -> AnchorData? {
        let removed = anchorDataMap.removeValue(forKey: id)
        if removed != nil {
            debugLog("🗑️ Anchor removed: \(id)")
        }
        return removed
    }
    
    /// 앵커 검색
    func getAnchor(id: UUID) -> AnchorData? {
        return anchorDataMap[id]
    }
    
    /// 특정 컬렉션의 모든 앵커 검색
    func getAnchors(for collectionID: UUID) -> [AnchorData] {
        return anchorDataMap.values.filter { $0.collectionID == collectionID }
    }
    
    /// 앵커와 컬렉션 연결
    func linkAnchorToCollection(anchorID: UUID, collectionID: UUID) throws {
        guard var data = anchorDataMap[anchorID] else {
            throw ARError.anchorNotFound(anchorID)
        }
        data.collectionID = collectionID
        anchorDataMap[anchorID] = data
    }
    
    /// 앵커 메모 텍스트 업데이트
    func updateMemoText(anchorID: UUID, text: String) throws {
        guard var data = anchorDataMap[anchorID] else {
            throw ARError.anchorNotFound(anchorID)
        }
        data.memoText = text
        anchorDataMap[anchorID] = data
    }
    
    /// 모든 앵커 제거
    func removeAllAnchors() {
        anchorDataMap.removeAll()
        debugLog("🗑️ All anchors removed")
    }
    
    private func debugLog(_ message: String) {
        #if DEBUG
        print("[AnchorManager] \(message)")
        #endif
    }
}

