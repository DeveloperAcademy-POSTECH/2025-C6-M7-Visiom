//
//  STTButton.swift
//  Visiom
//
//  Created by 윤창현 on 11/6/25.
//

import SwiftUI

struct STTButton: View {
    @Bindable var speechRecognizer: SpeechRecognizer
    @Binding var text: String
    @State private var showAuthorizationAlert = false
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: { toggleRecording() }) {
            HStack(spacing: 8) {
                Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                    .font(.title2)
                    .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
                
                Text(speechRecognizer.isRecording ? "녹음 중지" : "음성 입력")
                    .font(.headline)
            }
            .foregroundStyle(speechRecognizer.isRecording ? .red : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(speechRecognizer.isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(speechRecognizer.isRecording ? Color.red : Color.blue, lineWidth: 2)
            )
            .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .alert("음성 인식 권한 필요", isPresented: $showAuthorizationAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("음성 인식 기능을 사용하려면 설정에서 권한을 허용해주세요.")
        }
        .onChange(of: speechRecognizer.recognizedText) { _, newValue in
            text = newValue
        }
        .onChange(of: speechRecognizer.isRecording) { _, isRecording in
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = isRecording
            }
        }
    }
    
    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            Task {
                let authorized = await speechRecognizer.requestAuthorization()
                
                if authorized {
                    do {
                        try speechRecognizer.startRecording()
                    } catch {
                        speechRecognizer.errorMessage = "녹음 시작 실패: \(error.localizedDescription)"
                    }
                } else {
                    showAuthorizationAlert = true
                }
            }
        }
    }
}
