//
//  Ext+FullImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

// MARK: - Setup Extension
extension FullImmersiveView {
    
    /// AR 세션 시작
    static func startARSession() async {
        guard HandTrackingProvider.isSupported else {
            print("error: 핸드 트래킹이 안됨")
            return
        }
        
        guard WorldTrackingProvider.isSupported else {
            print("error: 월드 트래킹이 안됨")
            return
        }
        
        do {
            try await arSession.run([handTracking, worldTracking])
        } catch {
            print("AR session failed")
        }
    }
    
    /// RealityView 초기 설정 - 손 추적 및 그리기 시스템
    @MainActor
    func setupRealityView(content: RealityViewContent) async {
        // SpatialTrackingSession 시작
        let trackingSession = SpatialTrackingSession()
        let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
        
        let unapprovedCapabilities = await trackingSession.run(configuration)
        
        if let unapproved = unapprovedCapabilities,
           unapproved.anchor.contains(.hand) {
            print("손 추적 권한이 거부되었습니다")
            return
        }
        
        spatialSession = trackingSession
        
        // 그림을 담을 부모 엔티티
        let drawingParent = Entity()
        content.add(drawingParent)
        
        // 오른손 앵커
        let rightIndexTipAnchor = AnchorEntity(
            .hand(.right, location: .indexFingerTip),
            trackingMode: .continuous
        )
        content.add(rightIndexTipAnchor)
        
        let rightThumbTipAnchor = AnchorEntity(
            .hand(.right, location: .joint(for: .middleFingerTip)),
            trackingMode: .continuous
        )
        content.add(rightThumbTipAnchor)
        
        // 왼손 앵커
        let leftIndexTipAnchor = AnchorEntity(
            .hand(.left, location: .indexFingerTip),
            trackingMode: .continuous
        )
        content.add(leftIndexTipAnchor)
        
        let leftThumbTipAnchor = AnchorEntity(
            .hand(.left, location: .thumbTip),
            trackingMode: .continuous
        )
        content.add(leftThumbTipAnchor)
        
        // 그리기 시스템 등록 및 설정
        DrawingSystem.registerSystem()
        DrawingSystem.rightIndexTipAnchor = rightIndexTipAnchor
        DrawingSystem.rightThumbTipAnchor = rightThumbTipAnchor
        DrawingSystem.leftIndexTipAnchor = leftIndexTipAnchor
        DrawingSystem.leftThumbTipAnchor = leftThumbTipAnchor
        DrawingSystem.drawingParent = drawingParent
    }
    
    /// 씬 초기 설정 - root 엔티티 및 그룹 생성
    @MainActor
    func setupScene(content: RealityViewContent) async {
        // 이미 로드된 경우 중복 추가 방지
        guard root == nil else {
            if let existingRoot = root {
                content.add(existingRoot)
            }
            return
        }
        
        // 씬 갈아끼기
        if let immersiveContentEntity = try? await Entity(
            named: "Immersive",
            in: realityKitContentBundle
        ) {
            immersiveContentEntity.generateCollisionShapes(recursive: true)
            root = immersiveContentEntity
            content.add(immersiveContentEntity)
            SceneManager.setupScene(in: immersiveContentEntity)
            
            // Photo 그룹 생성
            let pGroup = Entity()
            pGroup.name = "PhotoGroup"
            pGroup.isEnabled = appModel.showPhotos
            root?.addChild(pGroup)
            self.photoGroup = pGroup
            
            // Memo 그룹 생성
            let mGroup = Entity()
            mGroup.name = "MemoGroup"
            mGroup.isEnabled = appModel.showMemos
            root?.addChild(mGroup)
            self.memoGroup = mGroup
        }
    }
}
