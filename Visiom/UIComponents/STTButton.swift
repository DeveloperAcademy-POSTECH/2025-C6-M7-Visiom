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
            Image(systemName: speechRecognizer.isRecording ? "pause" : "mic")
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.white)
                .frame(width: 300, height: 70)
        }
        .frame(width: 300, height: 70)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .overlay(
            RoundedRectangle(cornerRadius: 35)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 35))
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
            withAnimation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
            ) {
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
                        speechRecognizer.errorMessage =
                            "녹음 시작 실패: \(error.localizedDescription)"
                    }
                } else {
                    showAuthorizationAlert = true
                }
            }
        }
    }
}
