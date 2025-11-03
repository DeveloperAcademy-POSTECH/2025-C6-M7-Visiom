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
    @Environment(MemoStore.self) var memoStore
    @ObservedObject var markerManager = MarkerVisibilityManager.shared

    @EnvironmentObject var drawingState: DrawingState
    
    @State private var inputText: String = ""
    
    var body: some View {
        if appModel.memoEditMode {
            TextFieldAttachmentView(
                text: $inputText
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
                    Image(systemName: "arrow.uturn.left")
                }
                
                Button {
                    appModel.itemAdd = .photo
                    print("사진 버튼 탭")
                } label: {
                    Image(systemName: "photo")
                }
                Button {
                    appModel.memoEditMode = true
                    
                    //                    let id = UUID()
                    //                    memoStore.createDraft(id: id)
                    //                    openWindow(id: appModel.memoEditWindowID, value: id)
                } label: {
                    Image(systemName: "text.document")
                }
                //            Button {
                //
                //            } label: {
                //                Text("스티커")
                //            }
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
                //            Button {
                //
                //            } label: {
                //                Text("마네킹")
                //            }
                Button {
                    appModel.togglePhotos()
                    appModel.toggleMemos()
                    print("Button 눌림.")
                    print("showPhotos: \(appModel.showPhotos)")
                    print("showMemos: \(appModel.showMemos)")
                    
                } label: {
                    Image(systemName: appModel.showPhotos ? "eye" : "eye.slash")
                }
                Button {
                    markerManager.isVisible.toggle()
                    
                } label: {
                    Image(systemName: markerManager.isVisible ? "figure.run.circle.fill" : "figure.run.circle")
                }
            }
            .glassBackgroundEffect()
        }
    }
}
