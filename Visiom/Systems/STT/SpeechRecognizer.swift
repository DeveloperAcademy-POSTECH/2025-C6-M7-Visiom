//
//  SpeechRecognizer.swift
//  Visiom
//
//  Created by 윤창현 on 11/6/25.
//

// MARK: - Speech Recognition Manager
import SwiftUI
import Speech
import AVFoundation

@Observable
class SpeechRecognizer {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var recognizedText = ""
    var isRecording = false
    var errorMessage: String?
    var isAuthorized = false
    
    init(locale: Locale = Locale(identifier: "ko-KR")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }
    
    // 권한 요청
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                let authorized = status == .authorized
                self.isAuthorized = authorized
                continuation.resume(returning: authorized)
            }
        }
    }
    
    // 녹음 시작
    func startRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            throw RecognitionError.requestInitializationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            
            if error != nil || result?.isFinal == true {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        errorMessage = nil
    }
    
    // 녹음 중지
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    // 리셋
    func reset() {
        recognizedText = ""
        errorMessage = nil
    }
}

enum RecognitionError: Error {
    case requestInitializationFailed
    case unauthorized
}
