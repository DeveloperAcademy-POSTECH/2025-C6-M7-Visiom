//
//  AnchorSystem.swift
//  Visiom
//
//  Created by Elphie on 11/9/25.
//
//  앵커가 추가/갱신/삭제 될 때,
//  레지스트리 업데이트
//  이미 스폰된 엔티티의 위치 동기화
//  새로운 엔티티 스폰을 맡는다.
//

import Foundation
import RealityKit
import ARKit

@MainActor
final class AnchorSystem {
    
    private let worldTracking: WorldTrackingProvider    // 앵커 이벤트를 확인용
    private let anchorRegistry: AnchorRegistry          // 앵커 기록 테이블
    private let persistence: PersistenceManager?        // 앵커의 디스크 저장/복원
    
    // 외부에서 관리하는 entity 사전에 AnchorID으로 접근
    private let entityForAnchorID: (UUID) -> Entity?
    private let setEntityForAnchorID: (UUID, Entity?) -> Void
    
    // 런타임 엔티티를 만드는 함수를 주입받아 호출
    private let spawnEntity: (AnchorRecord) async -> Void
    
    /// 레코드가 없는 앵커가 추가되었을 때 처리 (예: memo 대기열 매칭 등)
    var onAnchorAddedWithoutRecord: ((WorldAnchor) async -> Void)?
    
    /// 앵커가 제거되었을 때 외부 정리
    var onAnchorRemoved: ((UUID) -> Void)?
    
    // 앵커 이벤트 루프를 도는 비동기 태스크
    private var updatesTask: Task<Void, Never>?
    // 디바운스 저장을 지연 실행하는 태스크(너무 잦은 저장 방지)
    private var pendingSaveTask: Task<Void, Never>?
    
    // MARK: Init
    init(
        worldTracking: WorldTrackingProvider,
        anchorRegistry: AnchorRegistry,
        persistence: PersistenceManager?,
        entityForAnchorID: @escaping (UUID) -> Entity?,
        setEntityForAnchorID: @escaping (UUID, Entity?) -> Void,
        spawnEntity: @escaping (AnchorRecord) async -> Void
    ) {
        self.worldTracking = worldTracking
        self.anchorRegistry = anchorRegistry
        self.persistence = persistence
        self.entityForAnchorID = entityForAnchorID
        self.setEntityForAnchorID = setEntityForAnchorID
        self.spawnEntity = spawnEntity
    }
    
    // MARK: Lifecycle
    // 이벤트 루프 태스크 시작
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            await self?.startObservingAnchorUpdatesLoop()
        }
    }
    
    // 돌고 있는 루프/디바운스 태스크 취소&해제
    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
    }
    
    // MARK: Anchor updates
    // 앵커 업데이트 모니터링
    func startObservingAnchorUpdatesLoop() async {
        for await update in worldTracking.anchorUpdates {
            if Task.isCancelled { break }
            switch update.event {
            case .added:
                await handleAnchorAdded(update.anchor)
            case .updated:
                handleAnchorUpdated(update.anchor)
            case .removed:
                handleAnchorRemoved(update.anchor.id)
            }
        }
    }
    
    // 앵커 추가 처리
    private func handleAnchorAdded(_ anchor: WorldAnchor) async {
        if let rec = anchorRegistry.get(anchor.id) {
            // 이미 복원된 레코드가 있고 아직 스폰되지 않았다면 스폰
            if entityForAnchorID(anchor.id) == nil {
                await spawnEntity(rec)
            }
            return
        }
        
        // 레코드가 없는 앵커: 외부 훅에 위임(예: 메모 대기열 매칭)
        await onAnchorAddedWithoutRecord?(anchor)
    }
    
    // 앵커 업데이트 처리
    private func handleAnchorUpdated(_ anchor: WorldAnchor) {
        var rec = anchorRegistry.get(anchor.id) ??
        AnchorRecord(
            id: anchor.id,
            kind: "unknown",
            dataRef: nil,
            transform: anchor.originFromAnchorTransform
        )
        
        rec.worldMatrix = anchor.originFromAnchorTransform
        anchorRegistry.upsert(rec)
        
        // 이미 스폰된 엔티티의 트랜스폼 동기화
        if let e = entityForAnchorID(anchor.id) {
            e.setTransformMatrix(rec.worldMatrix, relativeTo: nil)
        }
        
        persistence?.save()
    }
    
    // 앵커 제거 처리
    private func handleAnchorRemoved(_ id: UUID) {
        anchorRegistry.remove(id)
        
        if let e = entityForAnchorID(id) {
            e.removeFromParent()
            setEntityForAnchorID(id, nil)
        }
        
        onAnchorRemoved?(id)
        persistence?.save()
    }
}
