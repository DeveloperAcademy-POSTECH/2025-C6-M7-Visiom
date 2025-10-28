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
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Button {
                Task {
                    await appModel.exitFullImmersive(
                        dismissImmersiveSpace: dismissImmersiveSpace,
                        openWindow: openWindow
                    )
                }
            } label: {
                Text("나가기")
            }

            Button {
                appModel.itemAdd = .photo
                print("사진 버튼 탭")
            } label: {
                Text("사진")
            }
            Button {
                appModel.itemAdd = .memo
            } label: {
                Text("메모")
            }
            Button {

            } label: {
                Text("숫자")
            }
            Button {

            } label: {
                Text("스티커")
            }
            Button {

            } label: {
                Text("마네킹")
            }
            Button {

            } label: {
                Text("필터")
            }
            Button {

            } label: {
                Text("이동")
            }
        }
        .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .automatic) {
    UserControlView()
        .environment(AppModel())
}
