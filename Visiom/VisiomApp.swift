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
    @State private var appModel = AppModel()
    @State private var collectionStore = CollectionStore()
    @State private var memoStore = MemoStore()
    @StateObject private var drawingState = DrawingState()

    var body: some Scene {
        WindowGroup(id: appModel.crimeSceneListWindowID) {
            CrimeSceneListView()
                .environment(appModel)
                .environment(memoStore)
        }.defaultSize(CGSize(width: 1191, height: 477))

        WindowGroup(id: "PhotoCollectionList") {
            PhotoCollectionListView()
                .environment(appModel)
                .environment(collectionStore)
                .environment(memoStore)
        }

        WindowGroup(id: appModel.photoCollectionWindowID, for: UUID.self) {
            $collectionID in
            if let id = collectionID {
                PhotoCollectionView(collectionID: id)
                    .environment(collectionStore)
                    .environment(memoStore)
            } else {
                Text("컬렉션이 선택되지 않았습니다.")
            }
        }
        
        WindowGroup(id: appModel.drawingControlWindowID) {
            DrawingControlView()
                .environmentObject(drawingState)
                .environment(memoStore)
        }.windowResizability(.contentSize)
        
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
        
        ImmersiveSpace(id: appModel.fullImmersiveSpaceID) {
            FullImmersiveView()
                .environment(appModel)
                .environment(collectionStore)
                .environmentObject(drawingState)
                .environment(memoStore)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background {
                        PhotoPipeline.cleanupTempFiles()
                        Task {
                            await collectionStore.flushSaves()
                        }
                    }
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
