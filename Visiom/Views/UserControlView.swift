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
    @ObservedObject var markerManager = MarkerVisibilityManager.shared

    @EnvironmentObject var drawingState: DrawingState
    
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
                    Task{
                        if drawingState.isDrawingEnabled {
                            drawingState.isDrawingEnabled = false
                            drawingState.isErasingEnabled = false
                            dismissWindow(id: appModel.drawingControlWindowID)
                            
                        } else {
                            drawingState.isDrawingEnabled = true
                            drawingState.isErasingEnabled = true
                            openWindow(id: appModel.drawingControlWindowID)
                            
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(
                            systemName: drawingState.isDrawingEnabled
                            ?  "pause.circle.fill" : "play.circle.fill"
                        )
                        .font(.system(size: 24))

                        Text(drawingState.isDrawingEnabled ? "그리기 정지" : "그리기")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Button {

                } label: {
                    Text("마네킹")
                }
                Button {
                    appModel.togglePhotos()
                    appModel.toggleMemos()
                    print("Button 눌림.")
print("showPhotos: \(appModel.showPhotos)")
                    print("showMemos: \(appModel.showMemos)")
                    
                } label: {
                    Text(appModel.showPhotos ? "visible" : "invisible")
                }
                Button {
                    markerManager.isVisible.toggle()

                } label: {
                    Text(markerManager.isVisible ? "정지" : "이동")
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
