//
//  MixedImmersiveView+gestures.swift
//  Visiom
//
//  Created by Elphie on 11/17/25.
//

import RealityKit
import SwiftUI

extension MixedImmersiveView {

    // MARK: - Gestures
    var tapEntityGesture: some Gesture {
        TapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                inputSurface.setLastHitEntity(value.entity)
                let p = value.entity.position(relativeTo: nil)
                let wp = SIMD3<Float>(p.x, p.y, p.z)
                inputSurface.onTap?(.zero, wp)
            }
    }
    
    var longPressEntityGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.75)
            .targetedToAnyEntity()
            .onEnded { value in
                inputSurface.setLastHitEntity(value.entity)
                inputSurface.onLongPress?(.zero)
            }
    }
    
    var dragEntityGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                inputSurface.setLastHitEntity(value.entity)
                let pNow = value.convert(value.location3D, from: .local, to: .scene)
                
                let world = SIMD3<Float>(pNow.x, pNow.y, pNow.z)
                inputSurface.pushDragSample(currentWorld: world, isEnded: false)
            }
            .onEnded { _ in
                inputSurface.pushDragSample(currentWorld: nil, isEnded: true)
            }
    }
}
