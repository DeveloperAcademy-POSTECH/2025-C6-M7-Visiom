//
//  MixedImmersiveController.swift
//  Visiom
//
//  Created by Elphie on 11/16/25.
//

import Foundation
import RealityKit
import ARKit
import SwiftUI

@MainActor
final class MixedImmersiveController {
    
    // MARK: - Dependencies
    let worldTracking: WorldTrackingProvider
    let anchorRegistry: AnchorRegistry
    let persistence: PersistenceManager
    let bootstrap: SceneBootstrap
    let placementManager: PlacementManager
    let openWindow: (String, Any?) -> Void
    let memoStore: MemoStore
    let collectionStore: CollectionStore
    let placedImageStore: PlacedImageStore
    let windowIDPhotoCollection: String
    
    // MARK: - Entities
    weak var root: Entity?
    weak var photoGroup: Entity?
    weak var memoGroup: Entity?
    weak var teleportGroup: Entity?
    weak var timelineGroup: Entity?
    weak var placedImageGroup: Entity?
    
    // MARK: - Mapping
    var entityByAnchorID: [UUID: Entity] = [:]
    
    // MARK: - Init
    init(
        worldTracking: WorldTrackingProvider,
        anchorRegistry: AnchorRegistry,
        persistence: PersistenceManager,
        bootstrap: SceneBootstrap,
        placementManager: PlacementManager,
        memoStore: MemoStore,
        collectionStore: CollectionStore,
        placedImageStore: PlacedImageStore,
        windowIDPhotoCollection: String,
        openWindow: @escaping (String, Any?) -> Void
    ) {
        self.worldTracking = worldTracking
        self.anchorRegistry = anchorRegistry
        self.persistence = persistence
        self.bootstrap = bootstrap
        self.placementManager = placementManager
        self.memoStore = memoStore
        self.collectionStore = collectionStore
        self.placedImageStore = placedImageStore
        self.windowIDPhotoCollection = windowIDPhotoCollection
        self.openWindow = openWindow
    }
}

// MARK: - Public Function
extension MixedImmersiveController {
    
    // 카메라 포즈를 가져와서 실제 앵커 생성 함수로 넘기는 함수
    func makePlacement(type: UserControlItem, dataRef:UUID? = nil) async {
        // 현재 시간을 기준으로 기기의 포즈(위치와 방향)를 가져옴
        let timestamp = CACurrentMediaTime()
        guard let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: timestamp) else {
            print("⚠️ deviceAnchor unavailable")
            return
        }
        await createAnchor(
            usingCamera: deviceAnchor.originFromAnchorTransform,
            for: type,
            dataRef: dataRef
        )
    }

    func refreshScene(
        showPhotos: Bool,
        showMemos: Bool,
        showTeleports: Bool,
        showTimelines: Bool,
        showPlacedImage: Bool
    ) {
        /// 역할: entity 계층 구조 점검하기
        updateEntityHierarchy()
        /// 역할: entity 계층에 따라 show/hide 설정하기
        updateGroupVisibility(
            showPhotos: showPhotos,
            showMemos: showMemos,
            showTeleports: showTeleports,
            showTimelines: showTimelines,
            showPlacedImage: showPlacedImage
        )
    }
}

// MARK: - Placement Flow
extension MixedImmersiveController {
    
    // 카메라 기준으로 앵커를 하나 만들고 WorldAnchor과 Entity를 스폰하는 오케스트레이터
    private func createAnchor(
        usingCamera cameraTransform: simd_float4x4,
        for type: UserControlItem,
        dataRef: UUID? = nil
    ) async {
        
        // 1) 카메라 앞 위치 계산
        let spawnPosition = computePlacementPosition(cameraTransform: cameraTransform, type: type)
        
        // 2) PlacementManager.place 로 초기 AnchorRecord 생성
        let anchorID: UUID
        switch type {
        case .photoCollection:
            anchorID = placementManager.place(
                kind: .photoCollection,
                dataRef: nil,
                forwardFrom: cameraTransform
            )
        case .memo:
            anchorID = placementManager.place(
                kind: .memo,
                dataRef: nil,
                forwardFrom: cameraTransform
            )
        case .teleport:
            anchorID = placementManager.place(
                kind: .teleport,
                dataRef: nil,
                forwardFrom: cameraTransform
            )
        case .timeline :
            anchorID = placementManager.place(
                kind: .timeline,
                dataRef: dataRef,
                forwardFrom: cameraTransform
            )
        case .placedImage :
            anchorID = placementManager.place(
                kind: .placedImage,
                dataRef: nil,
                forwardFrom: cameraTransform
            )
        default : fatalError("Unknown item type: \(type)")
        }
        
        guard var anchorRecord = anchorRegistry.records[anchorID] else { return }
        
        // 3) Camera rotation 유지 + translation만 교체
        var t = Transform(matrix: anchorRecord.worldMatrix)
        t.translation = spawnPosition
        anchorRecord.worldMatrix = t.matrix
        anchorRegistry.upsert(anchorRecord)
        
        // 4) WorldAnchor 추가
        do {
            try await addWorldAnchor(for: anchorRecord)
            await handlePlacement(for: type, anchorRecord: anchorRecord, dataRef: dataRef)
        } catch {
            print("⚠️ 월드 앵커 추가 failed")
        }
    }
    
    /// ARKit WorldAnchor 등록
    private func addWorldAnchor(for anchorRecord: AnchorRecord) async throws {
        let anchor = WorldAnchor(originFromAnchorTransform: anchorRecord.worldMatrix)
        try await worldTracking.addAnchor(anchor)
    }
    
    /// 종류별 후처리 + 스폰
    private func handlePlacement(for type: UserControlItem, anchorRecord: AnchorRecord, dataRef: UUID?) async {
        
        switch type {
        case .photoCollection:
            await handlePhotoCollectionPlacement(anchorRecord)
        case .memo:
            await handleMemoPlacement(anchorRecord)
        case .teleport:
            await handleTeleportPlacement(anchorRecord)
        case .timeline:
            await handleTimelinePlacement(anchorRecord, dataRef: dataRef)
        case .placedImage:
            await handlePlacedImagePlacement(anchorRecord, dataRef: dataRef)
        default:
            break
        }
    }
}

// MARK: - Placement Handlers
extension MixedImmersiveController {
    
    private func handlePhotoCollectionPlacement(_ anchorRecord: AnchorRecord) async {
        var modifiedRecord = anchorRecord
        
        // 1) DB에 PhotoCollection 생성
        let photoCollection = collectionStore.createCollection()
        collectionStore.renameCollection(photoCollection.id, to: photoCollection.id.uuidString)
        
        // 2) dataRef 연결 후 save
        modifiedRecord.dataRef = photoCollection.id
        anchorRegistry.upsert(modifiedRecord)
        
        // 3) 스폰
        await spawnEntity(modifiedRecord)
        persistence.save()
        
        // 4) 윈도우 열기
        openWindow(windowIDPhotoCollection, photoCollection.id)
    }
    
    private func handleMemoPlacement(_ anchorRecord: AnchorRecord) async {
        guard let memoID = memoStore.memoToAnchorID else {
            print("⚠️ memoID missing")
            return
        }
        var modifiedRecord = anchorRecord
        modifiedRecord.dataRef = memoID
        anchorRegistry.upsert(modifiedRecord)
        
        await spawnEntity(modifiedRecord)
        persistence.save()
    }
    
    private func handleTeleportPlacement(_ anchorRecord: AnchorRecord) async {
        anchorRegistry.upsert(anchorRecord)
        await spawnEntity(anchorRecord)
        persistence.save()
    }
    
    private func handleTimelinePlacement(_ anchorRecord: AnchorRecord, dataRef: UUID?) async {
        guard let timelineID = dataRef else {
            print("⚠️ timelineID missing")
            return
        }
        
        var modifiedRecord = anchorRecord
        modifiedRecord.dataRef = timelineID
        anchorRegistry.upsert(modifiedRecord)
        
        // 3) 즉시 스폰(런타임 표현) — 부트스트랩과 동일한 규약 사용
        await spawnEntity(modifiedRecord)
        persistence.save()
    }
    
    private func handlePlacedImagePlacement(_ anchorRecord: AnchorRecord, dataRef: UUID?) async {
        guard let placedImageID = placedImageStore.placedImageToAnchorID else {
            print("⚠️ placedImageID missing")
            return
        }
        
        var modifiedRecord = anchorRecord
        modifiedRecord.dataRef = placedImageID
        anchorRegistry.upsert(modifiedRecord)
        
        await spawnEntity(modifiedRecord)
        persistence.save()
    }
}

// MARK: - Spawn Entity
extension MixedImmersiveController {
    
    func spawnEntity(_ anchorRecord: AnchorRecord) async {
        
        guard entityByAnchorID[anchorRecord.id] == nil else { return }
        guard let kind = EntityKind(rawValue: anchorRecord.kind) else { return }
        guard let root else { return }
        
        print("🌱 spawnEntity kind:", kind, "anchorID:", anchorRecord.id)   // ⬅️ 4

        
        // 부모 그룹 선택
        let parent: Entity = {
            switch kind {
            case .photoCollection: return photoGroup ?? root
            case .memo:            return memoGroup ?? root
            case .teleport:        return teleportGroup ?? root
            case .timeline:        return timelineGroup ?? root
            case .placedImage:     return placedImageGroup ?? root
            }
        }()
        
        // Entity 생성
        let entity: Entity
        switch kind {
        case .photoCollection:
            guard let ref = anchorRecord.dataRef else { return }
            entity = EntityFactory.makePhotoCollection(anchorID: anchorRecord.id, dataRef: ref)
        case .memo:
            guard let ref = anchorRecord.dataRef else { return }
            entity = EntityFactory.makeMemo(anchorID: anchorRecord.id, dataRef: ref)
        case .teleport:
            entity = EntityFactory.makeTeleport(anchorID: anchorRecord.id)
        case .timeline:
            guard let ref = anchorRecord.dataRef else { return }
            entity = EntityFactory.makeTimeline(anchorID: anchorRecord.id, dataRef: ref)
        case .placedImage:
            guard let ref = anchorRecord.dataRef else { return }
            entity = EntityFactory.makePlacedImage(anchorID: anchorRecord.id, dataRef: ref)
        @unknown default:
            fatalError("Unknown entity kind: \(kind)")
        }
        
        // Visual attach
        await bootstrap.attachVisual(for: kind, to: entity, record: anchorRecord)
        
        // Transform 적용 + 부모 연결
        entity.transform.matrix = anchorRecord.worldMatrix
        parent.addChild(entity)
        
        entityByAnchorID[anchorRecord.id] = entity
    }
}

// MARK: - Spawn Position
extension MixedImmersiveController {
    
    /// 카메라 앞 0.5m 위치 계산
    private func computePlacementPosition(cameraTransform: simd_float4x4, type: UserControlItem) -> SIMD3<Float> {
        
        // 카메라 위치
        let devicePosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // 카메라가 바라보는 방향 벡터
        let forwardVector = -SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )
        
        // 벡터 길이 값 1로 맞추기
        let flatForwardVector = normalize(SIMD3<Float>(forwardVector.x, 0, forwardVector.z))
        let distance: Float = 0.5
        
        switch type {
        case .teleport, .timeline:
            return SIMD3<Float>(
                devicePosition.x + flatForwardVector.x * distance,
                0, // y=0 고정
                devicePosition.z + flatForwardVector.z * distance
            )
        case .memo, .photoCollection, .placedImage:
            return devicePosition + flatForwardVector * distance
        default:
            return devicePosition + flatForwardVector * distance
        }
    }
}

// MARK: - Hierarchy & Visibility
extension MixedImmersiveController {
    
    /// 엔티티 계층 구조 업데이트
    func updateEntityHierarchy() {
        guard let root else { return }
        
        for entity in entityByAnchorID.values {
            // 부모 없으면 root로
            if entity.parent == nil {
                root.addChild(entity)
            }
            
            // root 아래에 있으면 그룹으로 이동
            if entity.parent === root,
               let policy = entity.components[InteractionPolicyComponent.self] {
                
                switch policy.kind {
                case .photoCollection:
                    photoGroup?.addChild(entity)
                case .memo:
                    memoGroup?.addChild(entity)
                case .teleport:
                    teleportGroup?.addChild(entity)
                case .timeline:
                    timelineGroup?.addChild(entity)
                case .placedImage:
                    placedImageGroup?.addChild(entity)
                }
            }
        }
    }
    
    func updateGroupVisibility(
        showPhotos: Bool,
        showMemos: Bool,
        showTeleports: Bool,
        showTimelines: Bool,
        showPlacedImage: Bool
    ) {
        photoGroup?.isEnabled = showPhotos
        memoGroup?.isEnabled = showMemos
        teleportGroup?.isEnabled = showTeleports
        timelineGroup?.isEnabled = showTimelines
        placedImageGroup?.isEnabled = showPlacedImage
    }
}

// MARK: - Update Overlay
extension MixedImmersiveController {
    
    @MainActor
    func refreshMemoOverlay(anchorID: UUID, memoID: UUID) async {
        guard let container = entityByAnchorID[anchorID] else { return }
        
        // 1) 기존 텍스트 오버레이 제거 (ViewAttachmentEntity만 골라서 제거)
        for child in container.children {
            if child is ViewAttachmentEntity {
                child.removeFromParent()
            }
        }
        
        // 2) 최신 텍스트로 새 오버레이 부착
        if let text = memoStore.memo(id: memoID)?.text, !text.isEmpty {
            let overlay = AREntityFactory.createMemoTextOverlay(text: text)
            container.addChild(overlay)
            overlay.setPosition(
                [0, 0, ARConstants.Position.memoTextZOffset],
                relativeTo: container
            )
        }
    }
}

// MARK: - Height Adjustment
extension MixedImmersiveController {
    func applyHeightAdjustment(customHeight: Float) async {
        do {
            // WorldTrackingProvider는 타임스탬프(Double)를 받음 최신 시각으로 쿼리
            let now = CACurrentMediaTime()
            if let deviceAnchor = worldTracking.queryDeviceAnchor(
                atTimestamp: now
                
            ) {
                let userHeight = deviceAnchor.originFromAnchorTransform.columns
                    .3.y
                
                print("현재 높이: \(userHeight)m")
                let offset = customHeight - userHeight
                
                // MainActor에서 UI(root 엔티티) 업데이트
                await MainActor.run {
                    root?.setPosition(
                        SIMD3<Float>(0, -offset, 0),
                        relativeTo: nil
                    )
                    print(
                        "시점 높이 적용됨: 원하는=\(customHeight), 실제=\(userHeight), offset=\(offset)"
                    )
                }
            } else {
                print("쿼리 실패. DeviceAnchor 못찾음")
            }
            
        }
        
    }
}
