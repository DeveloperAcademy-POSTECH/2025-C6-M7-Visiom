//
//  MiniMapView.swift
//  Visiom
//
//  Created by 윤창현 on 11/18/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - Mini Window
struct MiniMapView: View {
    @Environment(MiniMapManager.self) private var miniMapManager
    
    var body: some View {
        RealityView { content in
            await miniMapManager.setupMiniScene(content: content)
        } update: { content in
            miniMapManager.updateMiniScene(content: content)
        }
    }
}
