//
//  RoomEntity+Configuration.swift
//  Visiom
//
//  Created by 윤창현 on 10/28/25.
//

import SwiftUI

extension RoomEntity {
    /// Configuration information for Earth entities.
    struct Configuration {

        var scale: Float = 0.6
        var rotation: simd_quatf = .init(angle: 0, axis: [0, 1, 0])
        var speed: Float = 0
        var position: SIMD3<Float> = .zero
        
    }

}



