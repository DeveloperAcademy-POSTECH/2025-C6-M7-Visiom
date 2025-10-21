//
//  TeleportRealityView.swift
//  Visiom
//
//  Created by 윤창현 on 10/20/25.
//

import SwiftUI
import RealityKit
import ARKit

struct TeleportRealityView: View {
    @Environment(AppModel.self) var appModel
    @Binding var position: SIMD3<Float>
    @Binding var rootEntity: Entity?
    
    var onTap: (Entity) -> Void
    
    var body: some View {
        RealityView { content in
            // 이미 로드된 경우 중복 추가 방지
            guard rootEntity == nil else {
                if let existingRoot = rootEntity {
                    content.add(existingRoot)
                }
                return
            }
            
            // usdz 파일 URL 확인
            guard let modelURL = Bundle.main.url(forResource: "test", withExtension: "usdz") else {
                print("❌ 'test.usdz' 파일 경로를 찾을 수 없음")
                return
            }
            
            
            do {
                // 모델 로드 시도
                let entity = try Entity.load(contentsOf: modelURL)
                
                // 로드 성공 → rootEntity 바인딩 갱신
                rootEntity = entity
                
                // RealityView 컨텐츠에 추가
                content.add(entity)
                
                // 씬 설정
                SceneManager.setupScene(in: entity)
                
                print("✅ 모델 로드 및 씬 설정 완료")
                
            } catch {
                print("❌ 모델 로드 실패: \(error.localizedDescription)")
            }
            
            
            
        } update: { content in
            // 씬을 반대 방향으로 이동 (사용자가 움직이는 효과)
            updateScenePosition()
            // 마커 가시성 업데이트
            updateMarkersVisibility()
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    onTap(value.entity)
                }
        )
        .onChange(of: appModel.markersVisible) { oldValue, newValue in
            updateMarkersVisibility()
        }
    }
    
    // MARK: - Update Scene Position
    private func updateScenePosition() {
        guard let root = rootEntity else { return }
        SceneManager.updateScenePosition(root: root, position: position)
    }
    
    // MARK: - Update Markers Visibility
    private func updateMarkersVisibility() {
        guard let root = rootEntity else { return }
        SceneManager.updateMarkersVisibility(root: root, visible: appModel.markersVisible)
    }
}

