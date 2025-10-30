//
//  DrawingSystem.swift
//  Visiom
//
//  Created by 윤창현 on 10/28/25.
//

import SwiftUI
import RealityKit

extension NSNotification.Name {
    static let clearAllDrawing = NSNotification.Name("clearAllDrawing")
}

class DrawingSystem: System {
    
    // MARK: - 오른손 (그리기)
    static var rightIndexTipAnchor: AnchorEntity?
    static var rightThumbTipAnchor: AnchorEntity?
    static var rightPreviousPosition: SIMD3<Float>?
    static var isDrawing = false
    static var isDrawingEnabled = true
    
    // MARK: - 왼손 (지우기)
    static var leftIndexTipAnchor: AnchorEntity?
    static var leftThumbTipAnchor: AnchorEntity?
    static var isErasing = false
    static var isErasingEnabled = true
    
    // MARK: - 그리기 설정
    static var drawingColor: UIColor = .systemBlue
    static var drawingRadius: Float = 0.003
    static var eraseRadius: Float = 0.05
    
    static var drawingParent: Entity?
    
    private var clearObserver: NSObjectProtocol?
    
    required init(scene: RealityKit.Scene) {
        clearObserver = NotificationCenter.default.addObserver(
            forName: .clearAllDrawing,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DrawingSystem.clearAll()
        }
    }
    
    deinit {
        if let observer = clearObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func update(context: SceneUpdateContext) {
        if DrawingSystem.isDrawingEnabled {
            handleDrawing()
        }
        
        if DrawingSystem.isErasingEnabled {
            handleErasing()
        }
    }
    
    // MARK: - 그리기 핸들러
    func handleDrawing() {
        guard let rightIndexTip = DrawingSystem.rightIndexTipAnchor,
              let rightThumbTip = DrawingSystem.rightThumbTipAnchor,
              let parent = DrawingSystem.drawingParent else {
            return
        }
        
        let indexPosition = rightIndexTip.position(relativeTo: nil)
        let thumbPosition = rightThumbTip.position(relativeTo: nil)
        let distance = simd_distance(indexPosition, thumbPosition)
        
        // 핀치 제스처 감지 (3cm 이내)
        if distance < 0.03 {
            if !DrawingSystem.isDrawing {
                DrawingSystem.isDrawing = true
                DrawingSystem.rightPreviousPosition = indexPosition
            } else if let prevPos = DrawingSystem.rightPreviousPosition {
                let moveDistance = simd_distance(prevPos, indexPosition)
                
                if moveDistance > 0.005 && moveDistance < 0.1 {
                    let sphere = ModelEntity(
                        mesh: .generateSphere(radius: DrawingSystem.drawingRadius),
                        materials: [SimpleMaterial(
                            color: DrawingSystem.drawingColor,
                            isMetallic: false
                        )]
                    )
                    sphere.position = indexPosition
                    parent.addChild(sphere)
                    
                    DrawingSystem.rightPreviousPosition = indexPosition
                }
            }
        } else {
            if DrawingSystem.isDrawing {
                DrawingSystem.isDrawing = false
                DrawingSystem.rightPreviousPosition = nil
            }
        }
    }
    
    // MARK: - 지우기 핸들러
    func handleErasing() {
        guard let leftIndexTip = DrawingSystem.leftIndexTipAnchor,
              let leftThumbTip = DrawingSystem.leftThumbTipAnchor,
              let parent = DrawingSystem.drawingParent else {
            return
        }
        
        // 검지와 엄지 위치 가져오기
        let indexPosition = leftIndexTip.position(relativeTo: nil)
        let thumbPosition = leftThumbTip.position(relativeTo: nil)
        
        // 두 손가락 사이의 거리 계산
        let distance = simd_distance(indexPosition, thumbPosition)
        
        let eraseRadius: Float = 0.05 // 5cm 반경
        
        // 핀치 제스처 감지 (3cm 이내)
        if distance < 0.03 {
            DrawingSystem.isErasing = true
            
            // 검지 위치 근처의 점들을 찾아서 제거
            for child in parent.children {
                let childPosition = child.position(relativeTo: nil)
                let distanceToEraser = simd_distance(indexPosition, childPosition)
                
                if distanceToEraser < eraseRadius {
                    child.removeFromParent()
                }
            }
            
            // === 지우기 영역 가시화 ===
            // 기존 지우기 표시 영역 제거
            parent.children.removeAll { entity in
                entity.name == "eraseIndicator"
            }
            
            // 새로운 지우기 표시 영역 생성 (반투명 빨간 구)
            let eraseIndicator = ModelEntity(
                mesh: .generateSphere(radius: eraseRadius),
                materials: [SimpleMaterial(
                    color: UIColor.white.withAlphaComponent(0.5),
                    isMetallic: false
                )]
            )
            eraseIndicator.name = "eraseIndicator"
            eraseIndicator.position = indexPosition
            
            parent.addChild(eraseIndicator)
            
        } else {
            DrawingSystem.isErasing = false
            
            // 핀치를 풀면 지우기 영역 표시 제거
            parent.children.removeAll { entity in
                entity.name == "eraseIndicator"
            }
        }
    }
    
    // MARK: - 유틸리티
    static func clearAll() {
        guard let parent = drawingParent else { return }
        parent.children.removeAll()
        isDrawing = false
        isErasing = false
        rightPreviousPosition = nil
    }
    
    static func setDrawingEnabled(_ enabled: Bool) {
        isDrawingEnabled = enabled
        if !enabled {
            isDrawing = false
            rightPreviousPosition = nil
        }
    }
    
    static func setErasingEnabled(_ enabled: Bool) {
        isErasingEnabled = enabled
        if !enabled {
            isErasing = false
        }
    }
    
    static func setDrawingColor(_ color: UIColor) {
        drawingColor = color
    }
}
