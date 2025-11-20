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
      
        HStack(spacing: 20) {
                    Button(action: {
                        miniMapManager.isRotated = true
                    }) {
                        Label("90도 회전", systemImage: "rotate.right")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        miniMapManager.isRotated = false
                    }) {
                        Label("원래대로", systemImage: "arrow.counterclockwise")
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
        RealityView { content in
            await miniMapManager.setupMiniScene(content: content)
        } update: { content in
            miniMapManager.updateMiniScene(content: content)
        }
    }
}
