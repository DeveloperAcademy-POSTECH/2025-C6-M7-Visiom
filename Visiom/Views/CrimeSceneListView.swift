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
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "circle.fill")
                Text("App Title")
                    .font(.system(size: 29, weight: .regular))
                    .tracking(0)
            }
            .padding(.leading, 24)
            .padding(.vertical, 28.5)

            Divider()

            ScrollView(.horizontal) {
                HStack(spacing: 24) {
                    Button(action: {
                        Task {
                            await appModel.enterFullImmersive(
                                openImmersiveSpace: openImmersiveSpace,
                                dismissWindow: dismissWindow
                            )
                        }
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy",
                            title: "Title",
                            description:
                                "Description"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            await appModel.enterFullImmersive(
                                openImmersiveSpace: openImmersiveSpace,
                                dismissWindow: dismissWindow
                            )
                        }
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy",
                            title: "Title",
                            description:
                                "Description"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            await appModel.enterFullImmersive(
                                openImmersiveSpace: openImmersiveSpace,
                                dismissWindow: dismissWindow
                            )
                        }
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy",
                            title: "Title",
                            description:
                                "Description"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            await appModel.enterFullImmersive(
                                openImmersiveSpace: openImmersiveSpace,
                                dismissWindow: dismissWindow
                            )
                        }
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy",
                            title: "Title",
                            description:
                                "Description"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 26)
            .padding(.top, 31)
            .padding(.bottom, 46)
            Spacer()
        }
    }
}

#Preview(windowStyle: .automatic) {
    CrimeSceneListView()
        .environment(AppModel())
}
