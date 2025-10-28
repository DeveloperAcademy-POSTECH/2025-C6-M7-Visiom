//
//  ImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI
import RealityKit
import ARKit

// TODO 리팩토링 후 삭제 예정
struct TeleportExampleView: View {
    @Environment(AppModel.self) var appModel
    @State private var position: SIMD3<Float> = [0, 0, 0]
    @State private var rootEntity: Entity?
    @State private var updateTimer: Timer?
    
    
    var body: some View {
        TeleportRealityView(
                   position: $position,
                   rootEntity: $rootEntity,
                   onTap: handleTap
               )
               .onAppear {
                   startTimer()
               }
               .onDisappear {
                   stopTimer()
               }
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateScenePosition()
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
    }
    
    // MARK: - Tap Handler
    private func handleTap(on entity: Entity) {
        let name = entity.name
        
        print("Tapped on: \(name)")
        
        // 텔레포트 마커 탭 처리
        if name.starts(with: "teleport_") {
            // 마커의 위치로 텔레포트 (y=0.5로 설정)
            let cubePosition = SIMD3<Float>(entity.position.x, 0.5, entity.position.z)
            teleportTo(cubePosition)
        }
    }
    
    // MARK: - Teleport
    private func teleportTo(_ cubePosition: SIMD3<Float>) {
        // 큐브의 위치로 position 설정
        position = cubePosition
        print("Teleported to cube at: \(position)")
        
        // 텔레포트 후 위치 즉시 업데이트
        updateScenePosition()
    }
    
    // MARK: - Update Scene Position
    private func updateScenePosition() {
        guard let root = rootEntity else { return }
        SceneManager.updateScenePosition(root: root, position: position)
    }
    
    
}
