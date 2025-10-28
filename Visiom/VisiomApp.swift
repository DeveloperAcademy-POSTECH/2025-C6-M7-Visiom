//
//  VisiomApp.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI

@main
struct VisiomApp: App {
    
    @StateObject private var drawingState = DrawingState()
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup(id: appModel.crimeSceneListWindowID) {
            CrimeSceneListView()
                .environment(appModel)
        }
        
        WindowGroup(id: appModel.drawingControlWindowID) {
            DrawingControlView()
                .environmentObject(drawingState)
        }.windowResizability(.contentSize)
        
        ImmersiveSpace(id: appModel.fullImmersiveSpaceID) {
            FullImmersiveView()
                .environment(appModel)
                .environmentObject(drawingState)
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
