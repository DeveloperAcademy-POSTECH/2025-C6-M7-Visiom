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
    //let fullImmersiveSpaceID = "FullImmersiveSpace"
    let mixedImmersiveSpaceID = "mixedImmersiveSpace"
    let crimeSceneListWindowID = "CrimeSceneListWindow"
    let photoCollectionWindowID = "PhotoCollectionWindow"
    let memoEditWindowID = "MemoEditWindow"
    let userControlWindowID = "UserControlWindow"
    let timelineWindowID = "TimelineWindow"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var itemAdd: UserControlItem? = nil
    //var memoToAnchorID: UUID? = nil
    var timelineToAnchorID: UUID? = nil

    // visible/invisible 상태 관리
    var markersVisible: Bool = true
    var showPhotos: Bool = true
    var showMemos: Bool = true
    var showTeleports: Bool = true
    var showTimelines: Bool = true
    var showPlacedImages: Bool = true
    
    var customHeight: Float = 1.60

    var showTopView: Bool = false
    
    func toggleMarkers() {
        markersVisible.toggle()
    }
    func togglePhotos() {
        showPhotos.toggle()
    }
    func toggleMemos() {
        showMemos.toggle()
    }
    func toggleTeleports() {
        showTeleports.toggle()
    }
    func toggleTimelines() {
        showTimelines.toggle()
    }
    func togglePlacedImages() {
        showPlacedImages.toggle()
    }

    //Mixed Immersive 진입 처리 함수
    @MainActor
    func enterMixedImmersive(
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
            switch await openImmersiveSpace(id: mixedImmersiveSpaceID) {
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
    func exitMixedImmersive(
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

//    //Full Immersive 진입 처리 함수
//    @MainActor
//    func enterFullImmersive(
//        openImmersiveSpace: OpenImmersiveSpaceAction,
//        dismissWindow: DismissWindowAction
//    ) async {
//        switch immersiveSpaceState {
//        case .open:
//            return
//        case .inTransition:
//            return
//        case .closed:
//            immersiveSpaceState = .inTransition
//            switch await openImmersiveSpace(id: fullImmersiveSpaceID) {
//            case .opened:
//                dismissWindow(id: crimeSceneListWindowID)
//                break
//            case .userCancelled, .error:
//                immersiveSpaceState = .closed
//            @unknown default:
//                immersiveSpaceState = .closed
//            }
//        }
//    }
//    
//    //Full Immersive 나가기 처리 함수
//    @MainActor
//    func exitFullImmersive(
//        dismissImmersiveSpace: DismissImmersiveSpaceAction,
//        dismissWindow: DismissWindowAction,
//        openWindow: OpenWindowAction
//    ) async {
//        guard immersiveSpaceState == .open else { return }
//        immersiveSpaceState = .inTransition
//        
//        await dismissImmersiveSpace()
//        closeImmersiveAuxWindows(dismissWindow: dismissWindow)
//        openWindow(id: crimeSceneListWindowID)
//    }
    
    func closeImmersiveAuxWindows(dismissWindow: DismissWindowAction) {
        dismissWindow(id: photoCollectionWindowID)
        dismissWindow(id: memoEditWindowID)
        dismissWindow(id: userControlWindowID)
        dismissWindow(id: timelineWindowID)
    }

    enum Route {
        case photoCollection(UUID)
        case memoEdit(UUID)
    }

    func open(routeString: String, openWindow: OpenWindowAction) {
        if routeString.hasPrefix("PhotoCollectionWindowID:"),
            let uuidStr = routeString.split(separator: ":").last,
            let id = UUID(uuidString: String(uuidStr))
        {
            openWindow(id: photoCollectionWindowID, value: id)
        } else if routeString.hasPrefix("MemoEditWindowID:"),
            let uuidStr = routeString.split(separator: ":").last,
            let id = UUID(uuidString: String(uuidStr))
        {
            openWindow(id: memoEditWindowID, value: id)
        }
    }

    func dismiss(routeString: String, dismissWindow: DismissWindowAction) {
        if routeString.hasPrefix("PhotoCollectionWindowID:") {
            dismissWindow(id: photoCollectionWindowID)
        } else if routeString.hasPrefix("MemoEditWindowID:") {
            dismissWindow(id: memoEditWindowID)
        }
    }
}
