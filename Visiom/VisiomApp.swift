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
    
    var body: some Scene {
        WindowGroup(id: appModel.crimeSceneListWindowID) {
            CrimeSceneListView()
                .environment(appModel)
        }
        
        WindowGroup(id: "PhotoCollectionList") {
            PhotoCollectionListView()
                .environment(collectionStore)
        }
        
        WindowGroup(id: appModel.photoCollectionWindowID, for: UUID.self) { $collectionID in
            if let id = collectionID {
                PhotoCollectionView(collectionID: id)
                    .environment(collectionStore)
            } else {
                Text("컬렉션이 선택되지 않았습니다.")
            }
        }
        
        ImmersiveSpace(id: appModel.fullImmersiveSpaceID) {
            FullImmersiveView()
                .environment(appModel)
                .environment(collectionStore)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
                .onChange(of: scenePhase) {_, phase in
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
