//
//  MixedImmersiveView+gestures.swift
//  Visiom
//
//  Created by Elphie on 11/17/25.
//

import RealityKit
import SwiftUI

extension MixedImmersiveView {
    @MainActor
    func startInteractionPipelineIfReady() {
        guard router == nil, gestureBridge == nil else { return }
        guard let placement = placementManager, let persistence = persistence else { return }
        
        let openRoute: (String) -> Void = { route in
            appModel.open(routeString: route, openWindow: openWindow)
        }
        let dismissRoute: (String) -> Void = { route in
            appModel.dismiss(routeString: route, dismissWindow: dismissWindow)
        }
        
        let ctx = InteractionContext(
            placement: placement,
            persistence: persistence,
            openWindow: openRoute,
            dismissWindow: dismissRoute
        )
        router = InteractionRouter(context: ctx)
        gestureBridge = GestureBridge(surface: inputSurface, router: router!)
        
        if placement.onMoved == nil {
            placementManager?.onMoved = { [self] rec in
                if let e = controller?.entityByAnchorID[rec.id] {
                    e.setTransformMatrix(rec.worldMatrix, relativeTo: nil)
                }
            }
        }
        if placement.onRemoved == nil {
            placementManager?.onRemoved = { [self] anchorID in
                if let e = controller?.entityByAnchorID.removeValue(forKey: anchorID) {
                    e.removeFromParent()
                }
                self.anchorRegistry.remove(anchorID)
                self.persistence?.save()
            }
        }
    }
    
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
                let pNow = value.convert(value.location3D, from: .local, to: value.entity.parent!)
                let world = SIMD3<Float>(pNow.x, pNow.y, pNow.z)
                inputSurface.pushDragSample(currentWorld: world, isEnded: false)
            }
            .onEnded { _ in
                inputSurface.pushDragSample(currentWorld: nil, isEnded: true)
            }
    }
}
