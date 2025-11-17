//
//  VisiomApp.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI

@main
struct VisiomApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @State private var appModel = AppModel()
    @State private var collectionStore = CollectionStore()
    @State private var memoStore = MemoStore()
    @State private var timelineStore = TimelineStore()
    @State private var entityManager = EntityManager()

    var body: some Scene {
        WindowGroup(id: appModel.crimeSceneListWindowID) {
            CrimeSceneListView()
                .environment(appModel)
        }.defaultSize(CGSize(width: 1191, height: 500))

        WindowGroup(id: appModel.userControlWindowID) {
            UserControlView()
                .environment(appModel)
                .environment(memoStore)
        }.defaultSize(CGSize(width: 700, height: 100))
            .windowResizability(.contentSize)
            .windowStyle(.plain)

        WindowGroup(id: appModel.photoCollectionWindowID, for: UUID.self) {
            $collectionID in
            if let id = collectionID {
                PhotoCollectionView(collectionID: id)
                    .environment(collectionStore)
            } else {
                Text("컬렉션이 선택되지 않았습니다.")
            }
        }

        WindowGroup(id: appModel.memoEditWindowID, for: UUID.self) {
            $memoID in
            if let id = memoID {
                MemoEditView(memoID: id)
                    .environment(appModel)
                    .environment(memoStore)
            } else {
                Text("메모가 선택되지 않았습니다.")
            }
        }
        .defaultSize(CGSize(width: 200, height: 220))
        .windowResizability(.contentSize)

        WindowGroup(id: appModel.timelineWindowID) {
            TimelineView()
                .environment(appModel)
                .environment(timelineStore)
        }
        .defaultSize(width: 400, height: 600)
        
        ImmersiveSpace(id: appModel.mixedImmersiveSpaceID) {
            MixedImmersiveView()
                .environment(appModel)
                .environment(collectionStore)
                .environment(entityManager)
                .environment(memoStore)
                .environment(timelineStore)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.closeImmersiveAuxWindows(
                        dismissWindow: dismissWindow
                    )
                    appModel.immersiveSpaceState = .closed
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        appModel.closeImmersiveAuxWindows(
                            dismissWindow: dismissWindow
                        )
                        PhotoPipeline.cleanupTempFiles()
                        Task {
                            await collectionStore.flushSaves()
                        }
                    }
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)

//        ImmersiveSpace(id: appModel.fullImmersiveSpaceID) {
//            FullImmersiveView()
//                .environment(appModel)
//                .environment(collectionStore)
//                .environment(entityManager)
//                .environment(memoStore)
//                .onAppear {
//                    appModel.immersiveSpaceState = .open
//                }
//                .onDisappear {
//                    appModel.closeImmersiveAuxWindows(
//                        dismissWindow: dismissWindow
//                    )
//                    appModel.immersiveSpaceState = .closed
//                }
//                .onChange(of: scenePhase) { _, phase in
//                    if phase == .background {
//                        appModel.closeImmersiveAuxWindows(
//                            dismissWindow: dismissWindow
//                        )
//                        PhotoPipeline.cleanupTempFiles()
//                        Task {
//                            await collectionStore.flushSaves()
//                        }
//                    }
//                }
//        }
//        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
