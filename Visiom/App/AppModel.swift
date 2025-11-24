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
    var timelineToAnchorID: UUID? = nil
    
    var customHeight: Float = 1.60
    var isMiniMap: Bool = false
    
    enum VisibilityKind: CaseIterable, Hashable {
        case photo
        case memo
        case timeline
        case placedImage
        case teleport
    }
    
    /// "현재 보이는 종류들"만 담는 Set
    /// 기본값: teleport만 숨김, 나머지 표시
    private(set) var visibleKinds: Set<VisibilityKind> = [
        .photo, .memo, .timeline, .placedImage
    ]
    
    /// 바인딩/읽기용 computed
    var showPhotos: Bool        { visibleKinds.contains(.photo) }
    var showMemos: Bool         { visibleKinds.contains(.memo) }
    var showTimelines: Bool     { visibleKinds.contains(.timeline) }
    var showPlacedImages: Bool  { visibleKinds.contains(.placedImage) }
    var isTeleportVisible: Bool { visibleKinds.contains(.teleport) }
    
    var onTimelineShow: ((UUID) -> Void)?  // show를 위해 index 순서대로 id를 받음
    var onTimelineHighlight: ((UUID) -> Void)?
    var selectedSceneFileName: String = "Immersive"
    
    //Mixed Immersive 진입 처리 함수
    @MainActor
    func enterMixedImmersive(
        openImmersiveSpace: OpenImmersiveSpaceAction,
        dismissWindow: DismissWindowAction
    ) async {
        resetVisibilityDefaults()
        
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
    
    //MARK: - Visible/Invisible 토글 관련 함수
    /// 명시적 set
    func setVisible(_ kind: VisibilityKind, _ isVisible: Bool) {
        if isVisible { visibleKinds.insert(kind) }
        else { visibleKinds.remove(kind) }
    }
    
    /// UI용 toggle (얇게)
    func toggle(_ kind: VisibilityKind) {
        setVisible(kind, !visibleKinds.contains(kind))
    }
    
    /// 전체 가시성
    func setAllVisible(_ isVisible: Bool, includeTeleport: Bool = false) {
        if isVisible {
            visibleKinds.formUnion([.photo, .memo, .timeline, .placedImage])
            if includeTeleport { visibleKinds.insert(.teleport) }
        } else {
            visibleKinds.subtract([.photo, .memo, .timeline, .placedImage])
            if includeTeleport { visibleKinds.remove(.teleport) }
        }
    }
    
    /// 앱 재시작/씬 변경 등에서 기본값으로 되돌릴 때
    func resetVisibilityDefaults() {
        visibleKinds = [.photo, .memo, .timeline, .placedImage]
    }
}
