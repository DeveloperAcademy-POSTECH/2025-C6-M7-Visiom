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
                        openWindow(id: appModel.userControlWindowID)
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy1",
                            title: "          거여동 밀실 살인 사건",
                            description:
                                "            2003년"
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
                        openWindow(id: appModel.userControlWindowID)
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy2",
                            title: "          서울 노량진 살인 사건",
                            description:
                                "            3030년"
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
                        openWindow(id: appModel.userControlWindowID)
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy3",
                            title: "          남양주 아파트 밀실 살인 사건",
                            description:
                                "            2010년"
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
                        openWindow(id: appModel.userControlWindowID)
                    }) {
                        CrimeSceneCard(
                            imageName: "crimeSceneDummy4",
                            title: "          애플 아카데미 사건",
                            description:
                                "            누가 범인일까"
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
        .onAppear {
            appModel.closeImmersiveAuxWindows(dismissWindow: dismissWindow)
        }
    }
        
}

#Preview(windowStyle: .automatic) {
    CrimeSceneListView()
        .environment(AppModel())
}
