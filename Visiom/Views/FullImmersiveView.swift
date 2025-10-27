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

enum ToolbarItem: String {
    case ball
    case box
} 

struct FullImmersiveView: View {
    @Environment(AppModel.self) var appModel

    private static let session = ARKitSession()
    private static let handTracking = HandTrackingProvider()
    private static let worldTracking = WorldTrackingProvider()

    @State private var root = Entity()

    @State private var worldAnchorEntities: [UUID: Entity] = [:]
    // 임시 객체 상태일 때 타입이랑 uuid를 저장하는 친구
    @State private var tempItemType: [UUID: ToolbarItem] = [:]

    @State private var isPlaced = false
    @State private var currentItem: ModelEntity? = nil
    @State private var currentItemType: ToolbarItem? = nil

    @State private var ball: ModelEntity = {
        let ball = ModelEntity(
            mesh: .generateSphere(radius: 0.05),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )

        let collision = CollisionComponent(shapes: [
            .generateSphere(radius: 0.05)
        ])
        let input = InputTargetComponent()  // 상호작용할 수 있는 객체임을 표시해주는 컴포넌트
        ball.components.set([collision, input])

        return ball
    }()

    @State private var box: ModelEntity = {
        let box = ModelEntity(
            mesh: .generateBox(size: 0.1),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        let collision = CollisionComponent(shapes: [
            .generateBox(size: [0.1, 0.1, 0.1])
        ])
        let input = InputTargetComponent()
        box.components.set([collision, input])
        return box
    }()

    var body: some View {
        VStack {
            // TO DO: UserControlView랑 합치기
            HStack {
                Button(action: { makePlacement(type: .ball) }) {
                    Text("ball 생성")
                }
                Button(action: {
                    makePlacement(type: .box)
                }) {
                    Text("박스 생성")
                }
            }
        }.disabled(isPlaced)
        RealityView { content in
            content.add(root)
            // 씬 갈아끼기
            if let immersiveContentEntity = try? await Entity(
                named: "Immersive",
                in: realityKitContentBundle
            ) {
                immersiveContentEntity.generateCollisionShapes(recursive: true)
                root.addChild(immersiveContentEntity)
            }

            let headAnchor = AnchorEntity(.head)
            content.add(headAnchor)

            let card = ViewAttachmentEntity()
            card.attachment = ViewAttachmentComponent(
                rootView: UserControlView()
            )
            card.position = [0, -0.3, -0.9]

            headAnchor.addChild(card)

        } update: { content in
            for (_, entity) in worldAnchorEntities {
                if !content.entities.contains(entity) {
                    content.add(entity)
                }
            }
        }
        .modifier(DragGestureImproved())
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
    }

    private static func startARSession() async {
        guard HandTrackingProvider.isSupported,
            WorldTrackingProvider.isSupported
        else {
            print("error: handtracking or worldtracking 안됨")
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

                    if tempItemType[update.anchor.id] == .box {
                        subjectClone = box.clone(recursive: true)
                    } else {
                        subjectClone = ball.clone(recursive: true)
                    }
                    subjectClone.name = update.anchor.id.uuidString
                    subjectClone.transform = Transform(
                        matrix: update.anchor.originFromAnchorTransform
                    )

                    worldAnchorEntities[update.anchor.id] = subjectClone
                    print("🟢 Anchor added \(update.anchor.id)")

                case .updated:
                    guard let entity = worldAnchorEntities[update.anchor.id]
                    else {
                        continue
                    }
                    entity.transform = Transform(
                        matrix: update.anchor.originFromAnchorTransform
                    )
                    print("🔵 Anchor updated \(update.anchor.id)")

                case .removed:
                    worldAnchorEntities[update.anchor.id]?.removeFromParent()
                    worldAnchorEntities.removeValue(forKey: update.anchor.id)
                    print("🔴 Anchor removed \(update.anchor.id)")
                }
            }
        } catch {
            print("ARKit session error \(error)")
        }
    }

    private func makePlacement(type: ToolbarItem) {
        guard !isPlaced else { return }

        // 손을 따라다니는 임시 객체를 생성
        let tempObject: ModelEntity

        if type == .ball {
            tempObject = ModelEntity(
                mesh: .generateSphere(radius: 0.05),
                materials: [
                    SimpleMaterial(color: .systemYellow, isMetallic: false)
                ]
            )
        } else {
            tempObject = ModelEntity(
                mesh: .generateBox(size: 0.1),
                materials: [
                    SimpleMaterial(color: .systemYellow, isMetallic: false)
                ]
            )
        }

        root.addChild(tempObject)
        print("객체 생성 완료")
        self.currentItem = tempObject
        self.currentItemType = type

        self.isPlaced = true
    }

    private func trackingHand(_ currentBall: ModelEntity) async {
        // 직전 상태 저장
        var tapDetectedLastFrame = false

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
                currentBall.position = indexTipPosition
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
                        } catch {
                            print("월드 앵커 추가 failed")
                        }
                    }
                }
            }
            tapDetectedLastFrame = tapDetected
        }
    }
}

#Preview(immersionStyle: .full) {
    FullImmersiveView()
        .environment(AppModel())
}
