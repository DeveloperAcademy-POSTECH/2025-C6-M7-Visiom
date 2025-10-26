//
//  CrimeSceneListView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import SwiftUI
import RealityKit

struct CrimeSceneListView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        VStack {
            Button {
                Task {
                    await appModel.enterFullImmersive(
                        openImmersiveSpace: openImmersiveSpace,
                        dismissWindow: dismissWindow
                    )
                }
            } label: {
                Text("몰입형 공간 진입하기")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    CrimeSceneListView()
        .environment(AppModel())
}
