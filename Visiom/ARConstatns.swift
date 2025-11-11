//
//  ARConstants.swift
//  Visiom
//
//  Created by 윤창현 on 10/31/25.
//
// 완료

import SwiftUI
import simd

/// AR 관련 모든 상수를 중앙에서 관리
enum ARConstants {
    // MARK: - 기하학 치수 (단위: 미터)
    enum Dimensions {
        /// 사진 버튼 반지름
        static let photoButtonRadius: Float = 0.03
        /// 사진 버튼 높이
        static let photoButtonHeight: Float = 0.005
        /// 메모 박스 크기 (정사각형)
        static let memoBoxSize: Float = 0.1
        /// 메모 박스 깊이
        static let memoBoxDepth: Float = 0.005
    }
    
    // MARK: - 위치 및 변환
    enum Position {
        /// 초기 제어 패널 위치
        static let controlPanelPosition: SIMD3<Float> = [0, 1.2, -0.9]
        /// 메모 텍스트 오프셋 (Z축)
        static let memoTextZOffset: Float = 0.0053
    }
    
    // MARK: - 제스처 감지
    enum Gesture {
        /// 탭 감지 거리 (손가락 끝 - 엄지 끝) (2cm)
        static let tapDistance: Float = 0.02
        /// 장시간 터치 최소 시간 (초)
        static let longPressDuration: TimeInterval = 0.75
    }
    
    // MARK: - 회전
    enum Rotation {
        /// 사진 버튼 회전 (X축, -90도)
        static let photoButtonRotation = simd_quatf(
            angle: -Float.pi / 2,
            axis: [1, 0, 0]
        )
    }
    
    // MARK: - 색상
    enum Colors {
        static let photoButton = UIColor.cyan
        static let memoBackground = UIColor(red: 0.35, green: 0.69, blue: 1, alpha: 1)
    }
    
    // MARK: - 텍스트
    enum TextFormatting {
        static let memoTextSize: CGFloat = 10
        static let memoFrameWidth: CGFloat = 90
        static let memoFrameHeight: CGFloat = 90
        static let backgroundOpacity: CGFloat = 0.5
    }
}
