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

struct CrimeSceneCard: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 218)
                .frame(maxWidth: .infinity)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,  // 왼쪽 위 모서리
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32  // 오른쪽 위 모서리
                    )
                )

            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .lineSpacing(5)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(5)
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
            .padding(.leading, 26)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 267, height: 308)
        .glassBackgroundEffect()
        .cornerRadius(32)
        .hoverEffect()

    }
}

#Preview(windowStyle: .automatic) {
    CrimeSceneListView()
        .environment(AppModel())
}
