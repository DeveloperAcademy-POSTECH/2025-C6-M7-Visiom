//
//  Ext+FullImmersiveView.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//

import ARKit
import RealityKit
import SwiftUI

// MARK: - Placement Extension
extension FullImmersiveView {

    func makePlacement(type: UserControlBar) async {

        // 현재 시간을 기준으로 기기의 포즈(위치와 방향)를 가져옴
        let timestamp = CACurrentMediaTime()
        guard
            let deviceAnchor = await Self.worldTracking.queryDeviceAnchor(
                atTimestamp: timestamp
            )
        else {
            print("ARKit Error: Failed to get device anchor.")
            // 기기 위치를 못 가져오면 일단 원점에라도 생성
            await createAnchor(at: matrix_identity_float4x4, for: type)
            return
        }

        let deviceTransform = deviceAnchor.originFromAnchorTransform

        // 기기의 위치
        let devicePosition = SIMD3<Float>(
            deviceTransform.columns.3.x,
            deviceTransform.columns.3.y,
            deviceTransform.columns.3.z
        )
        let deviceForwardVector = -SIMD3<Float>(
            deviceTransform.columns.2.x,
            deviceTransform.columns.2.y,
            deviceTransform.columns.2.z
        )

        // 방향 벡터를 평평하게(이렇게 하면 수평 방향(X, Z)만 남음)
        let flatForwardVector = normalize(
            SIMD3<Float>(deviceForwardVector.x, 0, deviceForwardVector.z)
        )

        let distance: Float = 1.0

        let headHeightOffset: Float = 0.0
        // 최종 위치 = 눈높이 위치+평평한 방향*거리
        let finalPosition =
            devicePosition + flatForwardVector * distance
            + SIMD3<Float>(0, headHeightOffset, 0)

        // 최종 변환 행렬 (위치만 설정, 회전은 0)
        let finalTransform = Transform(translation: finalPosition).matrix

        // 이 위치에 앵커 생성 요청
        await createAnchor(at: finalTransform, for: type)

    }

    func createAnchor(at transform: simd_float4x4, for type: UserControlBar)
        async
    {

        await MainActor.run {
            Task {
                do {
                    // 사용자 앞에 앵커 추가 (현재는 월드 원점에 아이덴티티 변환으로 배치)
                    let anchor = WorldAnchor(
                        originFromAnchorTransform: transform
                    )
                    // 생성된 WorldAnchor를 worldTracking 프로바이더에 추가
                    try await Self.worldTracking.addAnchor(anchor)

                    if type == .memo {
                        memoText[anchor.id] = appModel.memoToAttach
                        appModel.memoToAttach = ""
                    }

                    if type == .photo {
                        let newCol = collectionStore.createCollection()
                        collectionStore.renameCollection(
                            newCol.id,
                            to: newCol.id.uuidString
                        )
                        anchorToCollection[anchor.id] = newCol.id
                    }

                    if let colId = pendingCollectionIdForNextAnchor {
                        anchorToCollection[anchor.id] = colId
                        pendingCollectionIdForNextAnchor = nil
                    }

                } catch {
                    print("월드 앵커 추가 failed")
                }
            }
        }

        print("객체 생성 완료")
    }
}
