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
    @State private var progress: Double = 0.0

    let crimeScenes = CrimeScene.mockData

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("icon")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .padding(.trailing, 16)
                Text("Re:Chain")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(0)
            }
            .padding(.leading, 24)
            .padding(.vertical, 22)

            Divider()

            ScrollView(.horizontal) {
                HStack(spacing: 24) {
                    ForEach(crimeScenes) { crimeScene in
                        Button(action: {
                            Task {
                                isLoading = true
                                progress = 0.0

                                Task {
                                    while progress < 1.0 {
                                        try? await Task.sleep(
                                            nanoseconds: 30_000_000
                                        )
                                        await MainActor.run {
                                            progress += 0.03
                                        }
                                    }
                                }

                                appModel.selectedSceneFileName =
                                    crimeScene.fileName

                                await appModel.enterMixedImmersive(
                                    openImmersiveSpace: openImmersiveSpace,
                                    dismissWindow: dismissWindow
                                )
                                progress = 1.0
                                isLoading = false

                                openWindow(id: appModel.userControlWindowID)
                            }
                        }) {
                            CrimeSceneCard(
                                imageName: crimeScene.imageName,
                                title: crimeScene.title,
                                occuredDate: crimeScene.occuredDate,
                                location: crimeScene.location,
                                status: crimeScene.status
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.leading, 26)
            .padding(.top, 21)
            Spacer()
        }
        .onAppear {
            appModel.closeImmersiveAuxWindows(dismissWindow: dismissWindow)
        }
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .clipShape(RoundedRectangle(cornerRadius: 44))
                    CrimeSceneLoadingView(progress: progress)
                }
            }
        }
    }

}
