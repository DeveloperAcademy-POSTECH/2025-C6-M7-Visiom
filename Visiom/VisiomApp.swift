//
//  VisiomApp.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI

@main
struct VisiomApp: App {
    
    @State private var appModel = AppModel()
    @State private var collectionStore = CollectionsStore()
    
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
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
