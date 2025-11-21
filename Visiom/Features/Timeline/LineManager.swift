//
//  Timeline.swift
//  Visiom
//
//  Created by jiwon on 11/14/25.
//
import SwiftUI
import RealityKit


@Observable
class LineManager {
    var entities: [Entity] = []
    
    var lines: [Entity] = []
    
    // 앵커 위치 임시 저장 배열
    var entityByAnchorIDs: [UUID:Entity] = [:]
    var anchorRecords : [AnchorRecord] = []
    
    var content: RealityViewContent?
    
    private let lineModelName = "arrow3"

    private let lengthAxis: Axis = .x
    
    enum Axis {
        case x, y, z
    }
    
    //
    //    func addEntity(at position: SIMD3<Float>) {
    //        guard let content = content else { return }
    //
    //        let sphere = ModelEntity(
    //            mesh: .generateSphere(radius: 0.05),
    //            materials: [SimpleMaterial(color: .red, isMetallic: false)]
    //        )
    //        sphere.position = position
    //        sphere.components.set(InputTargetComponent())
    //        sphere.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.05)]))
    //
    //        entities.append(sphere)
    //        content.add(sphere)
    //
    //        Task {
    //            await updateLines()
    //        }
    //    }
    
    // mixedImmersive에서 사용하는 entityByAnchorID를 entityByAnchorIDs로 넣기
//    func updateAnchor(entityByAnchorID: [UUID : Entity]) {
//        entityByAnchorIDs = entityByAnchorID
//        print("LineManager entityByAnchorIDs \(entityByAnchorID)")
//    }
    func updateAnchor(anchorRecord: AnchorRecord) {
           anchorRecords.append(anchorRecord)
           print("AnchorRecord \(anchorRecord)")
       }
    
    func updateLines() async {
                guard let content = content else { return }
        
        
        //        lines.forEach { $0.removeFromParent() }
        //        lines.removeAll()
        //
        //        for i in 1..<entities.count {
        //            let line = await createLine(
        //                from: entities[i-1].position,
        //                to: entities[i].position
        //            )
        //            lines.append(line)
        //            content.add(line)
        //        }
        
//        entities = Array(entityByAnchorIDs.values)
        print("updateLines entities : \(entities)")
        lines.forEach { $0.removeFromParent() }
        lines.removeAll()
        
        for i in 1..<anchorRecords.count {
            let line = await createLine(
                from: anchorRecords[i-1].worldMatrix,
                to: anchorRecords[i].worldMatrix
            )
            lines.append(line)
            content.add(line)
        }
    }
    
    func clear() {
        entities.forEach { $0.removeFromParent() }
        lines.forEach { $0.removeFromParent() }
        entities.removeAll()
        lines.removeAll()
    }
    
    
//    private func createLine(from start: SIMD3<Float>, to end: SIMD3<Float>) async -> Entity {
    private func createLine(from start: simd_float4x4, to end: simd_float4x4) async -> Entity {
        let startTranslation = SIMD3<Float>(start.columns.3.x, start.columns.3.y, start.columns.3.z)
        let endTranslation = SIMD3<Float>(end.columns.3.x, end.columns.3.y, end.columns.3.z)
        
        
        
        let distance = simd_distance(startTranslation, endTranslation)
        let direction = normalize(endTranslation - startTranslation)
        
        do {
            // USDZ 모델 로드
            let lineModel = try await Entity(named: lineModelName)
            
            // 모델의 경계 확인
            let bounds = lineModel.visualBounds(relativeTo: nil)
            
            // 길이 축에 따른 원래 길이와 스케일 계산
            let originalLength: Float
            var scale = SIMD3<Float>(0.02, 0.01, 0.01)
            
            
            lineModel.scale = scale
            
            // 중간 지점에 위치
            let midPoint = (startTranslation + endTranslation) / 2
            //            lineModel.position = midPoint
            
            // 🎯 위치 오프셋: 앞뒤로 밀려있으면 여기서 조절
            lineModel.position = midPoint + SIMD3<Float>(0, 0, 0)  // Z축으로 0.1 이동
            
            // 회전 계산
            let up: SIMD3<Float>
            switch lengthAxis {
            case .x:
                up = SIMD3<Float>(1, 0, 0)
            case .y:
                up = SIMD3<Float>(0, 1, 0)
            case .z:
                up = SIMD3<Float>(0, 0, 1)
            }
            
            if abs(dot(direction, up)) < 0.999 {
                let rotationAxis = normalize(cross(up, direction))
                let angle = acos(dot(up, direction))
                lineModel.orientation = simd_quatf(angle: angle, axis: rotationAxis)
            } else if dot(direction, up) < 0 {
                // 반대 방향인 경우 180도 회전
                let perpAxis: SIMD3<Float>
                switch lengthAxis {
                case .x:
                    perpAxis = SIMD3<Float>(0, 1, 0)
                case .y:
                    perpAxis = SIMD3<Float>(1, 0, 0)
                case .z:
                    perpAxis = SIMD3<Float>(1, 0, 0)
                }
                lineModel.orientation = simd_quatf(angle: .pi, axis: perpAxis)
            }
            
            return lineModel
            
        } catch {
            print("❌ USDZ 로드 실패: \(error)")
            // 실패 시 기본 실린더 반환
            return createDefaultCylinder(from: startTranslation, to: endTranslation)
        }
    }
    
    // 백업용 기본 실린더
    private func createDefaultCylinder(from start: SIMD3<Float>, to end: SIMD3<Float>) -> ModelEntity {
        let distance = simd_distance(start, end)
        let direction = normalize(end - start)
        
        let cylinder = ModelEntity(
            mesh: .generateCylinder(height: distance, radius: 0.005),
            materials: [SimpleMaterial(color: .blue, isMetallic: false)]
        )
        
        let midPoint = (start + end) / 2
        cylinder.position = midPoint
        
        let up = SIMD3<Float>(0, 1, 0)
        if abs(dot(direction, up)) < 0.999 {
            let rotationAxis = normalize(cross(up, direction))
            let angle = acos(dot(up, direction))
            cylinder.orientation = simd_quatf(angle: angle, axis: rotationAxis)
        } else if dot(direction, up) < 0 {
            cylinder.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
        }
        
        return cylinder
    }
    
}

