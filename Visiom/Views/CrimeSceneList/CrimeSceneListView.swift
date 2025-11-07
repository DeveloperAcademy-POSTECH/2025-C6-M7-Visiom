//
//  CrimeSceneListView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import RealityKit
import SwiftUI

struct CrimeSceneListView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @State private var isLoading = false
    let crimeScenes = CrimeScene.mockData

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "circle.fill")
                Text("Re:Chain")
                    .font(.system(size: 29, weight: .regular))
                    .tracking(0)
            }
            .padding(.leading, 24)
            .padding(.vertical, 28.5)

            Divider()

            ScrollView(.horizontal) {
                HStack(spacing: 24) {
                    ForEach(crimeScenes) { crimeScene in
                        Button(action: {
                            Task {
                                isLoading = true

                                await appModel.enterFullImmersive(
                                    openImmersiveSpace: openImmersiveSpace,
                                    dismissWindow: dismissWindow
                                )
                                isLoading = false
                            }
                            openWindow(id: appModel.userControlWindowID)
                        }) {
                            CrimeSceneCard(
                                imageName: crimeScene.imageName,
                                title: crimeScene.title,
                                description: crimeScene.description
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.leading, 26)
            .padding(.top, 31)
            .padding(.bottom, 46)
            Spacer()
        }
        .onAppear {
            appModel.closeImmersiveAuxWindows(dismissWindow: dismissWindow)
        }
        .disabled(isLoading)
        //        .fullScreenCover(isPresented: $isLoading) {
        //            CrimeSceneLoadingView()
        //        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    CrimeSceneLoadingView()
                }
            }
        }
    }

}

#Preview(windowStyle: .automatic) {
    CrimeSceneListView()
        .environment(AppModel())
}
