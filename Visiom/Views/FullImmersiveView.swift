//
//  FullImmersiveView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct FullImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    @State private var session: SpatialTrackingSession?
    @EnvironmentObject var drawingState: DrawingState
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        RealityView { content in
            
            await setupRealityView(content: content)

            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)

            let card = ViewAttachmentEntity()
            card.attachment = ViewAttachmentComponent(rootView: UserControlView())
            card.position = [0, -0.3, -0.9]
            
            headAnchor.addChild(card)

        }
        .onChange(of: drawingState.isDrawingEnabled) {
            DrawingSystem.isDrawingEnabled = drawingState.isDrawingEnabled
        }
        .onChange(of: drawingState.isErasingEnabled) {
            DrawingSystem.isErasingEnabled = drawingState.isErasingEnabled
        }
    }
    
    // MARK: - RealityKit 설정
    @MainActor
    private func setupRealityView(content: RealityViewContent) async {
        // SpatialTrackingSession 시작
        let trackingSession = SpatialTrackingSession()
        let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
        
        let unapprovedCapabilities = await trackingSession.run(configuration)
        
        if let unapproved = unapprovedCapabilities,
           unapproved.anchor.contains(.hand) {
            print("손 추적 권한이 거부되었습니다")
            return
        }
        
        self.session = trackingSession
        
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
            .hand(.right, location: .thumbTip),
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
        
        // 초기 상태 적용
        DrawingSystem.setDrawingEnabled(drawingState.isDrawingEnabled)
        DrawingSystem.setErasingEnabled(drawingState.isErasingEnabled)
    }
}

 #Preview(immersionStyle: .full) {
 FullImmersiveView()
 .environment(AppModel())
 }
 
