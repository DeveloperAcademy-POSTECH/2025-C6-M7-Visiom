//
//  AppModel.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    // TODO : ImmersiveView 사용하지 않는 것 확인 후 id 삭제 필요
    let immersiveSpaceID = "ImmersiveSpace"
    
    let fullImmersiveSpaceID = "FullImmersiveSpace"
    let crimeSceneListWindowID = "CrimeSceneListWindow"
    let photoCollectionWindowID = "PhotoCollectionWindow"
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
}
