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
    @Environment(\.dismissWindow) private var dismissWindow
    
    @StateObject private var drawingState = DrawingState()

    @State private var inputText: String = ""

    var body: some View {
        if appModel.memoEditMode {
            TextFieldAttachmentView(
                text: $inputText,
            )
            Button("작성 완료") {
                appModel.memoToAttach = inputText
                inputText = ""
                appModel.memoEditMode = false
                appModel.itemAdd = .memo
            }
        } else {
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
                    appModel.memoEditMode = true
                } label: {
                    Text("메모")
                }
                Button {

            } label: {
                Text("스티커")
            }
            Button {
                if  drawingState.isDrawingEnabled {
                    openWindow(id:appModel.drawingControlWindowID)
                    drawingState.toggleDrawing()
                    print("활성화")
                } else {
                    dismissWindow(id:appModel.drawingControlWindowID)
                    drawingState.toggleDrawing()
                    print("비활성화")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: drawingState.isDrawingEnabled ?
                          "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 24))
                    
                    Text(drawingState.isDrawingEnabled ? "활성화" : "비활성화")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(drawingState.isDrawingEnabled ?
                            Color.green.opacity(0.7) :
                                Color.red.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
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
}

#Preview(windowStyle: .automatic) {
    UserControlView()
        .environment(AppModel())
}
