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
    @Environment(CollectionStore.self) var collectionStore
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    // 그리기 전역 상태
    @EnvironmentObject var drawingState: DrawingState
    // 공간 추적 세션
    @State private var session: SpatialTrackingSession?
    
    private static let session = ARKitSession()
    private static let handTracking = HandTrackingProvider()
    private static let worldTracking = WorldTrackingProvider()
    
    // teleport
    @State private var position: SIMD3<Float> = [0, 0, 0]
    @State private var root: Entity? = nil
    @State private var updateTimer: Timer?
    @ObservedObject var markerManager = MarkerVisibilityManager.shared
    
    @State private var worldAnchorEntityData: [UUID: WorldAnchorEntityData] =
    [:]
    // 임시 객체 상태일 때 타입이랑 uuid를 저장하는 친구
    @State private var tempItemType: [UUID: UserControlBar] = [:]
    
    @State private var isPlaced = false
    @State private var currentItem: ModelEntity? = nil
    @State private var currentItemType: UserControlBar? = nil
    
    @State private var anchorToCollection: [UUID: UUID] = [:]
    @State private var pendingCollectionIdForNextAnchor: UUID? = nil
    
    @State private var memoText: [UUID: String] = [:]
    
    @State private var photoGroup: Entity?
    @State private var memoGroup: Entity?
    
    let photoButtonEntity: ModelEntity = {
        let photoBtn = ModelEntity(
            mesh: .generateCylinder(height: 0.005, radius: 0.03),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        
        let collision = CollisionComponent(shapes: [
            .generateSphere(radius: 0.03)
        ])
        let input = InputTargetComponent()  // 상호작용할 수 있는 객체임을 표시해주는 컴포넌트
        photoBtn.components.set([collision, input])
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
        memo.components.set([collision, input])
        return memo
    }()
    
    var body: some View {
        RealityView { content in
            await setupRealityView(content: content)
            
            
            // 이미 로드된 경우 중복 추가 방지
            guard root == nil else {
                if let existingRoot = root {
                    content.add(existingRoot)
                }
                return
            }
            
            // 씬 갈아끼기
            if let immersiveContentEntity = try? await Entity(
                named: "Immersive",
                in: realityKitContentBundle
            ) {
                immersiveContentEntity.generateCollisionShapes(recursive: true)
                root = immersiveContentEntity
                content.add(immersiveContentEntity)
                SceneManager.setupScene(in: immersiveContentEntity)
                
                
                let pGroup = Entity()
                pGroup.name = "PhotoGroup"
                pGroup.isEnabled = appModel.showPhotos
                root?.addChild(pGroup)
                self.photoGroup = pGroup
                
                let mGroup = Entity()
                mGroup.name = "MemoGroup"
                mGroup.isEnabled = appModel.showMemos
                root?.addChild(mGroup)
                self.memoGroup = mGroup
            }
            
            // (보류) 따라다니는 headAnchor
            //            let headAnchor = AnchorEntity(.head)
            //            content.add(headAnchor)
            
            let card = ViewAttachmentEntity()
            card.attachment = ViewAttachmentComponent(
                rootView: UserControlView()
                    .environment(appModel)
            )
            card.position = [0, 1.2, -0.9]
            
            card.components.set(InputTargetComponent())
            card.generateCollisionShapes(recursive: true)
            
            content.add(card)
            
        }update: { content in
            // teleport
            updateScenePosition()
            updateMarkersVisibility()
            
            // root가 없으면 root 붙이기 스킵
            guard let root = root else {
                photoGroup?.isEnabled = appModel.showPhotos
                memoGroup?.isEnabled  = appModel.showMemos
                return
            }
            
            for (uuid, data) in worldAnchorEntityData {
                // 부모가 없는 entity는 root 밑에 붙이기
                if data.entity.parent == nil {
                    root.addChild(data.entity)
                }
                
                // root 밑에 있는 entity 부모 찾아주기
                if data.entity.parent === root {
                    if tempItemType[uuid] == .photo, let pg = photoGroup {
                        pg.addChild(data.entity)
                    } else if tempItemType[uuid] == .memo, let mg = memoGroup {
                        mg.addChild(data.entity)
                    }
                }
            }
            
            
            
            photoGroup?.isEnabled = appModel.showPhotos
            memoGroup?.isEnabled = appModel.showMemos
        }
        .onChange(of: drawingState.isDrawingEnabled) {
            DrawingSystem.isDrawingEnabled = drawingState.isDrawingEnabled
        }
        .onChange(of: drawingState.isErasingEnabled) {
            DrawingSystem.isErasingEnabled = drawingState.isErasingEnabled
        }
        .modifier(DragGestureImproved())
        .disabled(isPlaced)

        // 객체 탭하면 동작
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // teleport
                    handleTap(on: value.entity)
                    
                    let targetEntity = value.entity
                    let anchorUUIDString = targetEntity.name
                    guard !anchorUUIDString.isEmpty,
                          let anchorUUID = UUID(uuidString: anchorUUIDString)
                    else {
                        print("Tapped entity has no valid UUID name.")
                        return
                    }
                    if let itemType = tempItemType[anchorUUID] {
                        switch itemType {
                        case .photo:
                            tapPhotoButton(anchorUUID)
                        case .memo:
                            tapMemoButton(memoId: anchorUUID)
                        }
                    } else {
                        print("Tapped entity's UUID not found in tempItemType.")
                    }
                }
        )
        .gesture(
            LongPressGesture(minimumDuration: 0.75)
                .targetedToAnyEntity()
                .onEnded { value in
                    let targetEntity = value.entity
                    
                    guard let anchorUUID = UUID(uuidString: targetEntity.name)
                    else {
                        return
                    }
                    
                    Task {
                        await removeWorldAnchor(by: anchorUUID)
                    }
                }
        )
        .task {
            await Self.startARSession()
        }
        .task {
            await self.observeUpdate()
        }
        .task(id: isPlaced) {
            guard isPlaced,
                  let currentItem
            else { return }
            await trackingHand(currentItem)
        }
        .onAppear {
            startTimer() // teleport
        }
        .onDisappear {
            stopTimer()// teleport
        }
        .onReceive( markerManager.$isVisible) { _ in// teleport
            updateMarkersVisibility()
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
    }
    
    private static func startARSession() async {
        guard HandTrackingProvider.isSupported
        else {
            print("error: 핸드 트래킹이 안됨")
            return
        }
        
        guard WorldTrackingProvider.isSupported
        else {
            print("error: 월드 트래킹이 안됨")
            return
        }
        do {
            try await session.run([handTracking, worldTracking])
        } catch {
            print("AR session falied")
        }
    }
    
    private func observeUpdate() async {
        do {
            for await update in Self.worldTracking.anchorUpdates {
                switch update.event {
                case .added:
                    let subjectClone: ModelEntity
                    
                    switch tempItemType[update.anchor.id] {
                    case .photo:
                        subjectClone = photoButtonEntity.clone(recursive: true)
                        (photoGroup ?? root)?.addChild(subjectClone)
                    case .memo:
                        subjectClone = memoEntity.clone(recursive: true)
                        (memoGroup ?? root)?.addChild(subjectClone)
                        if let memotext = memoText[update.anchor.id],
                           !memotext.isEmpty
                        {
                            let memoTextField = ViewAttachmentEntity()
                            memoTextField.attachment = ViewAttachmentComponent(
                                rootView: Text(memotext)
                                    .frame(width: 90, height: 90)
                                    .background(.regularMaterial.opacity(0.5))
                                    .foregroundColor(.black)
                                    .font(.system(size: 10))
                            )
                            memoTextField.setPosition(
                                [0, 0, 0.0053],
                                relativeTo: subjectClone
                            )
                            subjectClone.addChild(memoTextField)
                        }
                    case .none:
                        print("⚠️ tempItemType 없음: \(update.anchor.id) — 엔티티 생성 스킵")
                        continue
                    }
                    subjectClone.name = update.anchor.id.uuidString
                    subjectClone.setTransformMatrix(
                        update.anchor.originFromAnchorTransform,
                        relativeTo: nil  // 월드 좌표 기준
                    )
                    
                    worldAnchorEntityData[update.anchor.id] =
                    WorldAnchorEntityData(
                        anchor: update.anchor,
                        entity: subjectClone
                    )
                    
                    print("🟢 Anchor added \(update.anchor.id)")
                    
                case .updated:
                    
                    if var updateAnchor = worldAnchorEntityData[
                        update.anchor.id
                    ] {
                        updateAnchor.entity.setTransformMatrix(
                            update.anchor.originFromAnchorTransform,
                            relativeTo: nil
                        )
                        
                        updateAnchor.anchor = update.anchor
                        
                        worldAnchorEntityData[update.anchor.id] = updateAnchor
                    }
                    print("🔵 Anchor updated \(update.anchor.id)")
                    
                case .removed:
                    if let removeAnchor = worldAnchorEntityData.removeValue(
                        forKey: update.anchor.id
                    ) {
                        removeAnchor.entity.removeFromParent()
                        tempItemType.removeValue(forKey: update.anchor.id)
                        memoText.removeValue(forKey: update.anchor.id)
                    }
                    print("🔴 Anchor removed \(update.anchor.id)")
                }
            }
        }
    }
    
    private func makePlacement(type: UserControlBar) {
        guard !isPlaced else { return }

        drawingState.isDrawingEnabled = false
        drawingState.isErasingEnabled = false

        // 손을 따라다니는 임시 객체를 생성
        let tempObject: ModelEntity
        
        if type == .photo {
            tempObject = photoButtonEntity.clone(recursive: true)
            
            let newCol = collectionStore.createCollection()
            collectionStore.renameCollection(
                newCol.id,
                to: newCol.id.uuidString
            )
            pendingCollectionIdForNextAnchor = newCol.id
        } else {
            tempObject = memoEntity.clone(recursive: true)
        }
        
        if let root {
            root.addChild(tempObject)
        }
        
        print("객체 생성 완료")
        self.currentItem = tempObject
        self.currentItemType = type
        self.isPlaced = true
    }
    
    private func trackingHand(_ currentBall: ModelEntity) async {
        // 직전 상태 저장
        var tapDetectedLastFrame = true
        
        // 계속 핸드트래킹의 업데이트 받기
        for await update in Self.handTracking.anchorUpdates {
            guard isPlaced else { return }
            
            guard update.anchor.chirality == .right,
                  update.anchor.isTracked,
                  let skeleton = update.anchor.handSkeleton
            else { continue }
            
            // 검지 끝 위치 가져오기
            let indexTipJoint = skeleton.joint(.indexFingerTip)
            let originFromWorld = update.anchor.originFromAnchorTransform
            let indexTipTransform =
            originFromWorld * indexTipJoint.anchorFromJointTransform
            let indexTipPosition = simd_make_float3(indexTipTransform.columns.3)
            
            // 객체 위치를 검지 끝 위치로 실시간 업데이트
            await MainActor.run {
                currentBall.setPosition(indexTipPosition, relativeTo: nil)
                
            }
            
            // 탭 감지
            // 엄지끝 위치 가져오기
            let thumbTipJoint = skeleton.joint(.thumbTip)
            let thumbTipTransform =
            originFromWorld * thumbTipJoint.anchorFromJointTransform
            let thumbTipPosition = simd_make_float3(thumbTipTransform.columns.3)
            
            // 엄지끝~검지끝 사이의 거리 계산
            let distance = simd_distance(indexTipPosition, thumbTipPosition)
            let tapDetected = distance < 0.02  // 2cm 이내면 탭으로 인식
            
            // 탭 감지 + 직전 상태는 탭 상태가 아니어야 함
            if tapDetected && !tapDetectedLastFrame {
                await MainActor.run {
                    print("placement")
                    
                    // ball의 최종 위치(월드 좌표) 가져와
                    let finalPosition = currentBall.transformMatrix(
                        relativeTo: nil
                    )
                    
                    currentBall.removeFromParent()
                    
                    self.isPlaced = false
                    self.currentItem = nil
                    
                    // 별도 Task에서 월드 앵커를 생성(MainActor에서 네트워킹/ARKit 작업을 하면 UI가 멈출 수 있음(?))
                    Task {
                        do {
                            // finalPosition의 최종 위치에 WorldAnchor를 생성
                            let anchor = WorldAnchor(
                                originFromAnchorTransform: finalPosition
                            )
                            // 생성된 WorldAnchor를 worldTracking 프로바이더에 추가
                            try await Self.worldTracking.addAnchor(anchor)
                            // 성공적으로 추가되면.. observeUpdate 함수의 for await 에서 .added 를 감지하고 씬에 add
                            await MainActor.run {
                                if let itemType = self.currentItemType {
                                    tempItemType[anchor.id] = itemType
                                    if itemType == .memo {
                                        memoText[anchor.id] =
                                        appModel.memoToAttach
                                        appModel.memoToAttach = ""
                                    }
                                }
                                
                                // 앵커ID와 컬렉션 ID를 연결함
                                if let colId =
                                    pendingCollectionIdForNextAnchor
                                {
                                    anchorToCollection[anchor.id] = colId
                                    pendingCollectionIdForNextAnchor = nil
                                }
                            }
                        } catch {
                            print("월드 앵커 추가 failed")
                        }
                    }
                }
            }
            tapDetectedLastFrame = tapDetected
        }
    }
    
    private func removeWorldAnchor(by id: UUID) async {
        do {
            if let anchorToRemove = worldAnchorEntityData[id]?.anchor {
                try await Self.worldTracking.removeAnchor(anchorToRemove)
                print("remove anchor: \(id)")
            } else {
                print("cannot find")
            }
        } catch {
            print("error: \(error)")
        }
    }
    
    private func tapPhotoButton(_ anchorUUID: UUID) {
        print("ball 클릭 ")
        guard let colId = anchorToCollection[anchorUUID] else {
            print("No collection mapped for anchor \(anchorUUID)")
            return
        }
        // PhotoCollectionWindow 열기
        openWindow(id: appModel.photoCollectionWindowID, value: colId)
        print("Opened collection window for \(colId)")
    }
    private func tapMemoButton(memoId: UUID) {
        print("box 클릭, text: \(memoText[memoId] ?? "no memo") ")
    }
    
    // MARK: - RealityKit 설정
    @MainActor
    private func setupRealityView(content: RealityViewContent) async {
        // SpatialTrackingSession 시작
        //        let trackingSession = SpatialTrackingSession()
        //        let configuration = SpatialTrackingSession.Configuration(tracking: [
        //            .hand
        //        ])
        //
        //        let unapprovedCapabilities = await trackingSession.run(configuration)
        //
        //        if let unapproved = unapprovedCapabilities,
        //            unapproved.anchor.contains(.hand)
        //        {
        //            print("손 추적 권한이 거부되었습니다")
        //            return
        //        }
        //
        //        self.session = trackingSession

        // 그림을 담을 부모 엔티티
        let drawingParent = Entity()
        content.add(drawingParent)
        
        // 오른손 앵커
        let rightIndexTipAnchor = AnchorEntity(
            .hand(.right, location: .indexFingerTip),
            trackingMode: .continuous
        )
        content.add(rightIndexTipAnchor)
        
        let rightThumbTipAnchor = AnchorEntity(
            .hand(.right, location: .joint(for: .middleFingerTip)),
            trackingMode: .continuous
        )
        content.add(rightThumbTipAnchor)
        
        // 왼손 앵커
        let leftIndexTipAnchor = AnchorEntity(
            .hand(.left, location: .indexFingerTip),
            trackingMode: .continuous
        )
        content.add(leftIndexTipAnchor)
        
        let leftThumbTipAnchor = AnchorEntity(
            .hand(.left, location: .thumbTip),
            trackingMode: .continuous
        )
        content.add(leftThumbTipAnchor)
        
        // 그리기 시스템 등록 및 설정
        DrawingSystem.registerSystem()
        DrawingSystem.rightIndexTipAnchor = rightIndexTipAnchor
        DrawingSystem.rightThumbTipAnchor = rightThumbTipAnchor
        DrawingSystem.leftIndexTipAnchor = leftIndexTipAnchor
        DrawingSystem.leftThumbTipAnchor = leftThumbTipAnchor
        DrawingSystem.drawingParent = drawingParent
    }
}

#Preview(immersionStyle: .full) {
    FullImmersiveView()
        .environment(AppModel())
}

// MARK: - Logic Extension
extension FullImmersiveView {
    // MARK: Timer 관리
    private func startTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateScenePosition()
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
    }
    
    // MARK: - Tap Handler
    private func handleTap(on entity: Entity) {
        let name = entity.name
        print("Tapped on: \(name)")
        
        // 텔레포트 마커 탭 처리
        if name.starts(with: "teleport_") {
            // 마커의 위치로 텔레포트 (y=0.5로 설정)
            let cubePosition = SIMD3<Float>(entity.position.x, 0.5, entity.position.z)
            teleportTo(cubePosition)
        }
    }
    
    // MARK: - Teleport 이동
    private func teleportTo(_ cubePosition: SIMD3<Float>) {
        position = cubePosition
        print("🌀 Teleported to cube at: \(position)")
        updateScenePosition()
    }
    
    // MARK: - 씬 업데이트
    private func updateScenePosition() {
        guard let root = root else { return }
        SceneManager.updateScenePosition(root: root, position: position)
    }
    
    private func updateMarkersVisibility() {
        guard let root = root else { return }
        SceneManager.updateMarkersVisibility(root: root, visible: markerManager.isVisible )
    }
}

