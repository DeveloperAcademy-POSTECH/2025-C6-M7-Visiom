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

struct WorldAnchorEntityData {
    var anchor: WorldAnchor
    var entity: Entity
}

struct FullImmersiveView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MemoStore.self) var memoStore
    @Environment(CollectionStore.self) var collectionStore
    @Environment(\.openWindow)  var openWindow
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
    
    @State var worldAnchorEntityData: [UUID: WorldAnchorEntityData] =
    [:]
    // 임시 객체 상태일 때 타입이랑 uuid를 저장하는 친구
    @State var tempItemType: [UUID: UserControlBar] = [:]
    
    @State var isPlaced = false
    @State var currentItem: ModelEntity? = nil
    @State var currentItemType: UserControlBar? = nil
    
    @State var anchorToCollection: [UUID: UUID] = [:]
    @State var pendingCollectionIdForNextAnchor: UUID? = nil
    
    @State var memoText: [UUID: String] = [:]
    
    @State var photoGroup: Entity?
    @State var memoGroup: Entity?
    
    // MARK: - ViewModels (상태 관리 분리)
    @StateObject var anchorManager = AnchorManager()
    
    
    let photoButtonEntity: ModelEntity = {
        let photoBtn = ModelEntity(
            mesh: .generateCylinder(height: 0.005, radius: 0.03),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        
        let collision = CollisionComponent(shapes: [
            .generateSphere(radius: 0.03)
        ])
        let input = InputTargetComponent()  // 상호작용할 수 있는 객체임을 표시해주는 컴포넌트
        photoBtn.components.set([collision, input, BillboardComponent()])
        photoBtn.transform.rotation = simd_quatf(
            angle: -Float.pi / 2,
            axis: [1, 0, 0]
        )
        
        return photoBtn
    }()
    
    let memoEntity: ModelEntity = {
        let memo = ModelEntity(
            mesh: .generateBox(width: 0.1, height: 0.1, depth: 0.005),
            materials: [SimpleMaterial(color: .yellow, isMetallic: false)]
        )
        let collision = CollisionComponent(shapes: [
            .generateBox(width: 0.1, height: 0.1, depth: 0.005)
        ])
        let input = InputTargetComponent()
        memo.components.set([collision, input, BillboardComponent()])
        return memo
    }()
    
    var body: some View {
        RealityView { content in
            await setupRealityView(content: content)
            await setupScene(content: content)
        }update: { content in
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
                makePlacement(type: itemType)
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
        .disabled(isPlaced)
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
        .task(id: isPlaced) {
            guard isPlaced, let currentItem else { return }
            await trackingHand(currentItem)
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
