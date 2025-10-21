//
//  ImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    
    @State private var inputText: String = "안녕하세요!"
    @State private var loadedEntity: Entity?
    
    var body: some View {
        RealityView { content in
            
        } update: { content in
            if let entity = loadedEntity {
                content.add(entity)
            }
        }
        .task {
            guard let url = Bundle.main.url(forResource: "ball", withExtension: "usdz") else {
                print("⚠️ Model file not found")
                return
            }
            
            do {
                loadedEntity = try await loadModelWithTextField(
                    from: url,
                    text: $inputText,
                )
            } catch {
                print("🚫 Failed to load model: \(error)")
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
