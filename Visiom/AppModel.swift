//
//  AppModel.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    // TODO : ImmersiveView 사용하지 않는 것 확인 후 id 삭제 필요
    let immersiveSpaceID = "ImmersiveSpace"

    let fullImmersiveSpaceID = "FullImmersiveSpace"
    let crimeSceneListWindowID = "CrimeSceneListWindow"
    let photoCollectionWindowID = "PhotoCollectionWindow"
    let drawingControlWindowID = "DrawingControlWindow"
    let memoEditWindowID = "MemoEditWindow"
    let userControlWindowID = "UserControlWindow"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var itemAdd: UserControlBar? = nil
    var markersVisible: Bool = true

    var memoEditMode: Bool = false
    var memoToAttach: String = ""
    
    // visible/invisible 상태 관리
    var showPhotos: Bool = true
    var showMemos: Bool = true

    func toggleMarkers() {
        markersVisible.toggle()
        print("Markers visibility: \(markersVisible)")  // TODO 삭제
    }
    
    func togglePhotos(){
        showPhotos.toggle()
    }
    func toggleMemos() {
        showMemos.toggle()
    }

    //Full Immersive 진입 처리 함수
    @MainActor
    func enterFullImmersive(
        openImmersiveSpace: OpenImmersiveSpaceAction,
        dismissWindow: DismissWindowAction
    ) async {
        switch immersiveSpaceState {
        case .open:
            return
        case .inTransition:
            return
        case .closed:
            immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: fullImmersiveSpaceID) {
            case .opened:
                dismissWindow(id: crimeSceneListWindowID)
                break
            case .userCancelled, .error:
                immersiveSpaceState = .closed
            @unknown default:
                immersiveSpaceState = .closed
            }
        }
    }

    //Full Immersive 나가기 처리 함수
    @MainActor
    func exitFullImmersive(
        dismissImmersiveSpace: DismissImmersiveSpaceAction,
        dismissWindow: DismissWindowAction,
        openWindow: OpenWindowAction
    ) async {
        guard immersiveSpaceState == .open else { return }
        immersiveSpaceState = .inTransition

        await dismissImmersiveSpace()
        closeImmersiveAuxWindows(dismissWindow: dismissWindow)
        openWindow(id: crimeSceneListWindowID)
    }
    
    func closeImmersiveAuxWindows(dismissWindow: DismissWindowAction) {
        dismissWindow(id: photoCollectionWindowID)
        dismissWindow(id: drawingControlWindowID)
        dismissWindow(id: memoEditWindowID)
        dismissWindow(id: userControlWindowID)
    }
}
