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
    
    /// 객체 배치 시작
    func makePlacement(type: UserControlBar) {
        guard !isPlaced else { return }
        
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
    
    /// 손 추적 및 배치 처리
    func trackingHand(_ currentBall: ModelEntity) async {
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
            let indexTipTransform = originFromWorld * indexTipJoint.anchorFromJointTransform
            let indexTipPosition = simd_make_float3(indexTipTransform.columns.3)
            
            // 객체 위치를 검지 끝 위치로 실시간 업데이트
            await MainActor.run {
                currentBall.setPosition(indexTipPosition, relativeTo: nil)
            }
            
            // 탭 감지
            // 엄지끝 위치 가져오기
            let thumbTipJoint = skeleton.joint(.thumbTip)
            let thumbTipTransform = originFromWorld * thumbTipJoint.anchorFromJointTransform
            let thumbTipPosition = simd_make_float3(thumbTipTransform.columns.3)
            
            // 엄지끝~검지끝 사이의 거리 계산
            let distance = simd_distance(indexTipPosition, thumbTipPosition)
            let tapDetected = distance < 0.02  // 2cm 이내면 탭으로 인식
            
            // 탭 감지 + 직전 상태는 탭 상태가 아니어야 함
            if tapDetected && !tapDetectedLastFrame {
                await MainActor.run {
                    print("placement")
                    
                    // ball의 최종 위치(월드 좌표) 가져와
                    let finalPosition = currentBall.transformMatrix(relativeTo: nil)
                    
                    currentBall.removeFromParent()
                    
                    self.isPlaced = false
                    self.currentItem = nil
                    
                    // 별도 Task에서 월드 앵커를 생성
                    Task {
                        do {
                            // finalPosition의 최종 위치에 WorldAnchor를 생성
                            let anchor = WorldAnchor(
                                originFromAnchorTransform: finalPosition
                            )
                            // 생성된 WorldAnchor를 worldTracking 프로바이더에 추가
                            try await Self.worldTracking.addAnchor(anchor)
                            
                            await MainActor.run {
                                if let itemType = self.currentItemType {
                                    tempItemType[anchor.id] = itemType
                                    if itemType == .memo {
                                        memoText[anchor.id] = appModel.memoToAttach
                                        appModel.memoToAttach = ""
                                    }
                                }
                                
                                // 앵커ID와 컬렉션 ID를 연결함
                                if let colId = pendingCollectionIdForNextAnchor {
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
}
