//
//  MemoEditView.swift
//  Visiom
//
//  Created by Elphie on 10/30/25.
//

import SwiftUI

struct MemoEditView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MemoStore.self) var memoStore
    @Environment(\.dismissWindow) private var dismissWindow

    let memoID: UUID
    
    @State private var speechRecognizer = SpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    
    private var textBinding: Binding<String> {
        Binding(
            get: { memoStore.memo(id: memoID)?.text ?? "" },
            set: { memoStore.updateText(id: memoID, to: $0) }
        )
    }

    var body: some View {
        ZStack {
            Color(red: 0.35, green: 0.69, blue: 1)
                .ignoresSafeArea()
            VStack {
                MultilineTextFieldAttachmentView(
                    text: textBinding,
                    placeholder: "메모를 입력하세요",
                    width: 525,
                    height: 440,
                    font: .system(size: 48),
                    cornerRadius: 0,
                )
                .background(Color.clear)
                
                // 실시간 인식 텍스트 표시 (선택사항)
                if speechRecognizer.isRecording && !speechRecognizer.recognizedText.isEmpty {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundStyle(.white)
                            .symbolEffect(.variableColor.iterative, isActive: true)
                        
                        Text("인식 중: \(speechRecognizer.recognizedText)")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // 버튼들
                HStack(spacing: 16) {
                    
                    // 음성 입력 버튼
                    STTButton(
                        speechRecognizer: speechRecognizer,
                        text: textBinding
                    )
                    
                    // 작성 완료 버튼
                    Button("작성 완료") {
                        // 녹음 중이면 먼저 중지
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopRecording()
                        }
                        
                        if memoStore.commit(id: memoID) {
                            appModel.memoToAnchorID = memoID
                            dismissWindow(id: appModel.memoEditWindowID)
                        }
                    }
                }
            }
            .padding(40)
        }
        .animation(.easeInOut(duration: 0.3), value: speechRecognizer.isRecording)
    }
}

