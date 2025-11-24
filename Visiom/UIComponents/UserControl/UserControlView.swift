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
    
    private var isTeleportVisible: Bool {
        appModel.isTeleportVisible
    }
    
    private let columns: [GridItem] = [
        GridItem(.fixed(90), spacing: 12),
        GridItem(.fixed(90), spacing: 12),
        GridItem(.fixed(90), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(UserControlItem.allCases, id: \.self) { item in
                
                // placedImage는 "빈칸"
                if item == .placedImage {
                    ZStack {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                } else {
                    UserControlGridButton(
                        item: item,
                        isActive: state.activeItem == item,
                        isEnabled: isEnabled(item),
                        onTap: { handleTap(item) }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
    
    private struct UserControlGridButton: View {
        let item: UserControlItem
        let isActive: Bool
        let isEnabled: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                Image(systemName: isActive ? item.selectedIcon : item.icon)
                    .font(.system(size: 24))
                    .frame(width: 56, height: 56)
                    .contentShape(Rectangle())
                    .opacity(isEnabled ? 1.0 : 0.3)
            }
            .help(item.description)
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .hoverEffect(.highlight)
            .frame(width: 90, height: 90)
        }
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
                await appModel.exitMixedImmersive(
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
            // 예: “사진/메모/타임라인/placedImage”만 한꺼번에 토글
                let anyHidden =
                    !appModel.showPhotos ||
                    !appModel.showMemos ||
                    !appModel.showTimelines ||
                    !appModel.showPlacedImages

                // 하나라도 숨겨져 있으면 -> 전부 보이기
                // 다 보이는 상태면 -> 전부 숨기기
                appModel.setAllVisible(anyHidden)
        case .timeline:
            if state == .timeline {
                openWindow(id: appModel.timelineWindowID)
                print("🗂️ 보드 열기")
            } else {
                dismissWindow(id: appModel.timelineWindowID)
                print("🗂️ 보드 닫기")
            }
            
            // 이동
        case .teleport:
            appModel.toggle(.teleport)
        case .miniMap:
            if case .miniMap = state {
                openWindow(id:appModel.miniMapWindowID)
                print("🗺️ 미니맵 시작")
            } else {
                dismissWindow(id: appModel.miniMapWindowID)
                print("🗺️ 미니맵 종료")
            }
            
        case .placedImage:
            print("nothing")
            
        case .cameraheight:
            if state == .cameraheight {
                openWindow(id: appModel.cameraHeightWindowID)
                print("📏 시점 조정 시작")
            } else {
                dismissWindow(id: appModel.cameraHeightWindowID)
                print("📏 시점 조정 종료")
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
