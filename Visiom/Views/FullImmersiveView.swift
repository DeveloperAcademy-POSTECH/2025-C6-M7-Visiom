//
//  FullImmersiveView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import ARKit
import RealityKit
import RealityKitContent
import SwiftUI

struct FullImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MemoStore.self) var memoStore
    @Environment(CollectionStore.self) var collectionStore
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow

    // 그리기 전역 상태
    @EnvironmentObject var drawingState: DrawingState
    // 공간 추적 세션
    @State var spatialSession: SpatialTrackingSession?

    static let arSession = ARKitSession()
    static let handTracking = HandTrackingProvider()
    static let worldTracking = WorldTrackingProvider()

    // teleport
    @State var position: SIMD3<Float> = [0, 0, 0]
    @State var root: Entity? = nil
    @State var updateTimer: Timer?
    @ObservedObject var markerManager = MarkerVisibilityManager.shared

    @State var anchorToCollection: [UUID: UUID] = [:]
    @State var pendingCollectionIdForNextAnchor: UUID? = nil

    @State var memoText: [UUID: String] = [:]

    @State var photoGroup: Entity?
    @State var memoGroup: Entity?

    // MARK: - ViewModels (상태 관리 분리)
    @StateObject var anchorManager = AnchorManager()

    var body: some View {
        RealityView { content in
            await setupRealityView(content: content)
            await setupScene(content: content)
        } update: { content in
            // teleport
            updateScenePosition()
            updateMarkersVisibility()
            updateEntityHierarchy()
            updateGroupVisibility()
        }
        .onChange(of: drawingState.isDrawingEnabled) {
            DrawingSystem.isDrawingEnabled = drawingState.isDrawingEnabled
        }
        .onChange(of: drawingState.isErasingEnabled) {
            DrawingSystem.isErasingEnabled = drawingState.isErasingEnabled
        }
        .onChange(of: appModel.itemAdd) { _, newValue in
            if let itemType = newValue {
                print("함수호출")
                Task {
                    await makePlacement(type: itemType)
                }
                appModel.itemAdd = nil
            }
        }
        .onChange(of: appModel.showPhotos) { _, newValue in
            photoGroup?.isEnabled = newValue
        }
        .onChange(of: appModel.showMemos) { _, newValue in
            memoGroup?.isEnabled = newValue
        }
        .modifier(DragGestureImproved())
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleTap(on: value.entity)
                    handleEntityTap(value.entity)
                }
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.75)
                .targetedToAnyEntity()
                .onEnded { value in
                    handleLongPress(value.entity)
                }
        )
        .task {
            await FullImmersiveView.startARSession()
        }
        .task {
            await observeAnchorUpdates()
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onReceive(markerManager.$isVisible) { _ in
            updateMarkersVisibility()
        }
    }
}
