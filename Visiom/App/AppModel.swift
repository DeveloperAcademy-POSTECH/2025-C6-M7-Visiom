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
    let mixedImmersiveSpaceID = "mixedImmersiveSpace"
    let crimeSceneListWindowID = "CrimeSceneListWindow"
    let photoCollectionWindowID = "PhotoCollectionWindow"
    let memoEditWindowID = "MemoEditWindow"
    let userControlWindowID = "UserControlWindow"
    let timelineWindowID = "TimelineWindow"
    let cameraHeightWindowID = "CameraHeightWindowID"
    let timelineShowWindowID = "TimelineShowWindowID"  // timeline안에 show 기능을 위한 윈도우
    let miniMapWindowID = "MiniMapWindow"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var itemAdd: UserControlItem? = nil
    var memoToAnchorID: UUID? = nil
    var timelineToAnchorID: UUID? = nil

    // visible/invisible 상태 관리
    var markersVisible: Bool = true
    var showPhotos: Bool = true
    var showMemos: Bool = true
    var showTeleports: Bool = true
    var showTimelines: Bool = true

    var customHeight: Float = 1.60

    var isMiniMap: Bool = false

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

    var onTimelineShow: ((UUID) -> Void)?  // show를 위해 index 순서대로 id를 받음
    var selectedSceneFileName: String = "Immersive"

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

    //Mixed Immersive 나가기 처리 함수
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

    func closeImmersiveAuxWindows(dismissWindow: DismissWindowAction) {
        dismissWindow(id: photoCollectionWindowID)
        dismissWindow(id: memoEditWindowID)
        dismissWindow(id: userControlWindowID)
        dismissWindow(id: timelineWindowID)
        dismissWindow(id: cameraHeightWindowID)
        dismissWindow(id: timelineShowWindowID)
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
