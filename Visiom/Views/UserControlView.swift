//
//  UserControlView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import SwiftUI

enum UserControlBar: String {
    case photo
    case memo
}

struct UserControlView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MemoStore.self) var memoStore
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var drawingState: DrawingState
    
    @ObservedObject var markerManager = MarkerVisibilityManager.shared
    
    @State var state: InteractionState = .idle
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(UserControlItem.allCases, id: \.self) { item in
                Button {
                    handleTap(item)
                } label: {
                    Image(systemName: iconName(for: item))
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .opacity(isEnabled(item) ? 1.0 : 0.3)
                        .padding(12)
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled(item))
                
                if item == .back || item == .mannequin || item == .visibility {
                    VDivider(height: 60)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(width: 800, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

extension UserControlView {
    
    // 버튼 동작 분기
    private func handleTap(_ item: UserControlItem) {
        guard UserControlItemLogic.isEnabled(item, when: state) else { return }
        let oldState = state
        state = UserControlItemLogic.apply(item, from: oldState)
        
        switch item {
            // 뒤로가기
        case .back:
            Task {
                await appModel.exitFullImmersive(
                    dismissImmersiveSpace: dismissImmersiveSpace,
                    dismissWindow: dismissWindow,
                    openWindow: openWindow
                )
            }
            
            // 사진 배치
        case .photo:
            if case .placing(.photo) = state {
                appModel.itemAdd = .photo
                print("📸 사진 배치 시작")
            } else {
                appModel.itemAdd = nil
                print("📸 사진 배치 종료")
            }
            
            // 메모 작성
        case .memo:
            if case .placing(.memo) = state {
                print("📝 메모 작성 시작")
            } else {
                print("📝 메모 모드 종료")
            }
            
            // 숫자 스티커
        case .number:
            if case .placing(.number) = state {
                print("🔢 숫자 배치 시작")
            } else {
                print("🔢 숫자 배치 종료")
            }
            
            // 스티커
        case .sticker:
            if case .placing(.sticker) = state {
                print("🎯 스티커 배치 시작")
            } else {
                print("🎯 스티커 배치 종료")
            }
            
            // 마네킹
        case .mannequin:
            if case .placing(.mannequin) = state {
                print("🧍 마네킹 배치 시작")
            } else {
                print("🧍 마네킹 배치 종료")
            }
            
            // 드로잉
        case .drawing:
            if state == .drawing{
                drawingState.isDrawingEnabled = true
                drawingState.isErasingEnabled = true
                openWindow(id: appModel.drawingControlWindowID)
                print("✏️ 드로잉 모드 시작")
            } else {
                drawingState.isDrawingEnabled = false
                drawingState.isErasingEnabled = false
                dismissWindow(id: appModel.drawingControlWindowID)
                print("✏️ 드로잉 모드 종료")
            }
            
            // 가시성 토글
        case .visibility:
            appModel.togglePhotos()
            appModel.toggleMemos()
            
            // 보드(타임라인)
        case .board:
            if state == .board {
                print("🗂️ 보드 열기")
            } else {
                print("🗂️ 보드 닫기")
            }
            
            // 이동
        case .moving:
            markerManager.isVisible.toggle()
        }
    }

    private func iconName(for item: UserControlItem) -> String {
        state.activeItem == item ? item.selectedIcon : item.icon
    }
    
    private func isEnabled(_ item: UserControlItem) -> Bool {
        UserControlItemLogic.isEnabled(item, when: state)
    }
}

struct VDivider: View {
    var height: CGFloat = 60
    var opacity: Double = 0.28
    
    var body: some View {
        Rectangle()
            .fill(.white.opacity(opacity))
            .frame(width: 1, height: height)
            .cornerRadius(0.5)
            .padding(12)
    }
}
