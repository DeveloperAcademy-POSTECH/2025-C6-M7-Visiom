//
//  UserControlView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//

import SwiftUI

struct UserControlView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MemoStore.self) var memoStore
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State var state: InteractionState = .idle
    
    @State private var entityCounter: [EntityType: Int] = [.sphere: 0, .box: 0]
    
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

                if item == .back || item == .visibility {
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
        case .photoCollection:
            if case .placing(.photoCollection) = state {
                appModel.itemAdd = .photoCollection
                print("📸 사진 배치 시작")
            } else {
                appModel.itemAdd = nil
                print("📸 사진 배치 종료")
            }
            
            // 메모 작성
        case .memo:
            if case .placing(.memo) = state {
                let memo = memoStore.createMemo(initialText: "")
                openWindow(id: appModel.memoEditWindowID, value: memo.id)
                print("📝 메모 작성 시작")
            } else {
                print("📝 메모 모드 종료")
            }
            // 가시성 토글
        case .visibility:
            appModel.togglePhotos()
            appModel.toggleMemos()
            
            // 보드(타임라인)
        case .board:
            if state == .board {
                openWindow(id:appModel.timelineWindowID)
                print("🗂️ 보드 열기")
            } else {
                dismissWindow(id: appModel.timelineWindowID)
                print("🗂️ 보드 닫기")
            }
            
            // 이동
        case .teleport:
            if case .placing(.teleport) = state{
                appModel.itemAdd = .teleport
                print("⚡️ 텔레포트 배치 시작")
            } else {
                appModel.itemAdd = nil
                print("⚡️ 텔레포트 배치 종료")
            }
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
