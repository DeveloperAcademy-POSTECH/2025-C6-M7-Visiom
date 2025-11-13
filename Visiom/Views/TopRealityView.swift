//
//  TopView.swift
//  Visiom
//
//  Created by 윤창현 on 11/13/25.
//

import SwiftUI
import RealityKit

struct TopRealityView: View {
    let entity: Entity?
    
    var body: some View {
        RealityView { content in
            if let entity {
                let clone = entity.clone(recursive: true)
                clone.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                clone.position = [0, 0, -2]
                
                // 크기를 조절하는 코드임 필요 없으면 삭제 가능
//                let bounds = clone.visualBounds(relativeTo: nil)
//                let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
//                if maxDim > 0 {
//                    let scale: Float = 1.5 / maxDim
//                    clone.scale = [scale, scale, scale]
//                }
                
                content.add(clone)
            }
        }
    }
}

