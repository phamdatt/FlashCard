//
//  SpeakingPracticeView.swift
//  flash-card
//
//  Created by Claude on 5/2/26.
//

import SwiftUI
import AppKit
import AVFoundation
import Speech

struct SpeakingPracticeView: View {
    let flashcards: [Flashcard]
    let topicId: Int
    let onComplete: (Int, Int) -> Void
    let onReset: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var fontSizeManager: FontSizeManager
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var totalAnswered: Int = 0
    @State private var isRecording: Bool = false
    @State private var recognizedText: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showCompletion: Bool = false
    @State private var srsAlgorithm = SRSAlgorithm()
    #if os(macOS)
    @State private var speechAudioEngine: AVAudioEngine?
    @State private var speechRecognitionTask: SFSpeechRecognitionTask?
    @State private var speechRecordingFile: AVAudioFile?
    @State private var speechRecordingFileURL: URL?
    #endif
    @State private var lastRecordingURL: URL?
    @State private var playbackPlayer: AVAudioPlayer?
    /// Countdown 3–2–1 trước khi bắt đầu nhận diện (chỉ khi dùng micro thật)
    @State private var recordingCountdown: Int? = nil

    var body: some View {
        if flashcards.isEmpty {
            ContentUnavailableView(
                "Không có flashcard",
                systemImage: "rectangle.on.rectangle.slash",
                description: Text("Chủ đề này chưa có flashcard để luyện tập")
            )
        } else if showCompletion {
            completionView
        } else if currentIndex < flashcards.count {
            practiceView
        } else {
            completionView
                .onAppear {
                    showCompletion = true
                }
        }
    }

    private var practiceView: some View {
        let flashcard = flashcards[currentIndex]
        
        return VStack(spacing: 24) {
            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("Câu \(currentIndex + 1)/\(flashcards.count)")
                        .font(.app(.headline))
                    Spacer()
                    if totalAnswered > 0 {
                        HStack(spacing: 6) {
Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                            Text("\(score)/\(totalAnswered)")
                                .font(.app(.subheadline))
                        }
                    }
                }
                ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Spacer()

            // Question card
            VStack(spacing: 20) {
                Image(systemName: "mic.fill")
                    .scaledFont(.xl4)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, isActive: isRecording)

                if let count = recordingCountdown, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                        .contentTransition(.numericText())
                } else if recordingCountdown == 0 {
                    Text("Bắt đầu!")
                        .font(.app(.title))
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }

                Text("Đọc to câu sau:")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)

                #if os(macOS)
                Text("Bật quyền Micro và Nhận diện giọng nói trong Cài đặt hệ thống → Quyền riêng tư nếu cần. Không dùng được thì sẽ hiện ô gõ đáp án.")
                    .font(.app(.caption))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                #endif

                if isRecording && recordingCountdown == nil && !recognizedText.isEmpty {
                    Text("Đang nghe: \(recognizedText)")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.horizontal)
                }

                Text(flashcard.questionDisplayText)
                    .scaledFont(.display)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.appBackgroundControl(isLight: colorScheme == .light))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)

                if showResult {
                    ThemeDivider()
                        .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        HStack {
                            if isCorrect {
                                GreenCheckmarkView(size: 28)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.app(.title2))
                                    .foregroundStyle(.red)
                            }
                            Text(isCorrect ? "Chính xác!" : "Chưa đúng")
                                .font(.app(.title2))
                                .fontWeight(.semibold)
                                .foregroundStyle(isCorrect ? .green : .red)
                        }

                        if !recognizedText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bạn đã nói:")
                                    .font(.app(.subheadline))
                                    .foregroundStyle(.secondary)
                                Text(recognizedText)
                                    .font(.app(.body))
                                    .foregroundStyle(.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.appBackgroundControl(isLight: colorScheme == .light))
                                    .cornerRadius(8)
                            }
                        }

                        if lastRecordingURL != nil {
                            Button(action: playLastRecording) {
                                Label("Nghe lại âm thanh vừa nói", systemImage: "speaker.wave.2.fill")
                                    .font(.app(.subheadline))
                                    .fontWeight(.medium)
                            }
                            .buttonStyle(.bordered)
                            .cursor(.pointingHand)
                        }

                        Text("Từ gốc (đáp án đúng): \(flashcard.questionDisplayText)")
                            .font(.app(.body))
                            .foregroundStyle(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            Spacer()

            // Action buttons
            if !showResult {
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .scaledFont(.xl2)
                        Text(isRecording ? "Dừng ghi âm" : "Bắt đầu ghi âm")
                            .font(.app(.headline))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
                .padding(.horizontal, 40)
            } else {
                Button(action: {
                    nextCard()
                }) {
                    Label("Tiếp theo", systemImage: "arrow.right.circle.fill")
                        .font(.app(.headline))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .cursor(.pointingHand)
                .keyboardShortcut(.return, modifiers: [])
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            requestMicrophonePermissionIfNeeded { }
        }
        .onDisappear {
            if isRecording {
                isRecording = false
            }
        }
    }

    private var completionView: some View {
        PracticeCompletedView(
            score: score,
            totalAnswered: totalAnswered,
            onContinue: {
                if let url = lastRecordingURL {
                    try? FileManager.default.removeItem(at: url)
                }
                lastRecordingURL = nil
                playbackPlayer = nil
                showCompletion = false
                currentIndex = 0
                score = 0
                totalAnswered = 0
                onReset()
            }
        )
        .onAppear {
            onComplete(score, totalAnswered)
        }
    }

    private func startRecording() {
        isRecording = true
        recognizedText = ""
        showResult = false

        requestMicrophonePermissionIfNeeded {
            #if os(macOS)
            self.requestSpeechAndStartRecordingOnMac()
            #else
            self.showTextInputDialog { text in
                self.recognizedText = text
                self.stopRecording()
            }
            #endif
        }
    }

    /// Gọi trước khi dùng micro: hiện hộp thoại xin quyền nếu chưa xác định.
    private func requestMicrophonePermissionIfNeeded(completion: @escaping () -> Void) {
        #if os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            DispatchQueue.main.async { completion() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async { completion() }
            }
        case .denied, .restricted:
            DispatchQueue.main.async { completion() }
        @unknown default:
            DispatchQueue.main.async { completion() }
        }
        #else
        completion()
        #endif
    }

    #if os(macOS)
    /// Xin quyền nhận diện giọng rồi countdown 3–2–1 + bắt đầu ghi âm, hoặc fallback dialog gõ đáp án.
    private func requestSpeechAndStartRecordingOnMac() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.startRecordingCountdownThenEngine()
                    return
                case .denied, .restricted, .notDetermined:
                    self.showTextInputDialog { text in
                        self.recognizedText = text
                        self.stopRecording()
                    }
                @unknown default:
                    self.showTextInputDialog { text in
                        self.recognizedText = text
                        self.stopRecording()
                    }
                }
            }
        }
    }

    /// Countdown 3, 2, 1 (có âm tick), rồi âm "sẵn sàng" và bật engine nhận diện.
    private func startRecordingCountdownThenEngine() {
        let locale = speechLocaleForCurrentCard()
        guard SFSpeechRecognizer(locale: locale)?.isAvailable == true else {
            showTextInputDialog { text in
                self.recognizedText = text
                self.stopRecording()
            }
            return
        }
        recordingCountdown = 3
        SoundManager.shared.playCountdownTick()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard self.recordingCountdown != nil else { return }
            self.recordingCountdown = 2
            SoundManager.shared.playCountdownTick()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard self.recordingCountdown != nil else { return }
            self.recordingCountdown = 1
            SoundManager.shared.playCountdownTick()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard self.recordingCountdown != nil else { return }
            self.recordingCountdown = 0
            SoundManager.shared.playRecordingReady()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.recordingCountdown = nil
                _ = self.startLiveSpeechRecognition()
            }
        }
    }

    /// Bắt đầu nhận diện giọng trực tiếp và ghi âm để nghe lại. Trả về true nếu chạy được, false nếu fallback.
    private func startLiveSpeechRecognition() -> Bool {
        let locale = speechLocaleForCurrentCard()
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            return false
        }
        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        let recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".caf")
        guard let recordingFile = try? AVAudioFile(forWriting: recordingURL, settings: format.settings) else {
            return false
        }
        speechRecordingFile = recordingFile
        speechRecordingFileURL = recordingURL

        let fileToWrite = recordingFile
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
            try? fileToWrite.write(from: buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            speechRecordingFile = nil
            speechRecordingFileURL = nil
            try? FileManager.default.removeItem(at: recordingURL)
            return false
        }
        speechAudioEngine = engine
        speechRecognitionTask = recognizer.recognitionTask(with: request) { [self] result, _ in
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                }
            }
        }
        return true
    }

    private func speechLocaleForCurrentCard() -> Locale {
        guard currentIndex < flashcards.count else { return Locale(identifier: "vi_VN") }
        let text = flashcards[currentIndex].questionDisplayText
        let hasCJK = text.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        if hasCJK { return Locale(identifier: "zh_CN") }
        return Locale(identifier: "vi_VN")
    }
    #endif

    private func stopRecording() {
        recordingCountdown = nil
        isRecording = false
        #if os(macOS)
        if let engine = speechAudioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            speechAudioEngine = nil
        }
        if let url = speechRecordingFileURL {
            lastRecordingURL = url
        }
        speechRecordingFile = nil
        speechRecordingFileURL = nil
        speechRecognitionTask?.cancel()
        speechRecognitionTask = nil
        #endif

        guard !recognizedText.isEmpty else { return }
        
        // So sánh với từ gốc (question), không phải nghĩa (answer)
        let flashcard = flashcards[currentIndex]
        let userAnswer = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctWord = flashcard.questionDisplayText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        isCorrect = userAnswer == correctWord ||
                   userAnswer.contains(correctWord) ||
                   correctWord.contains(userAnswer)
        
        totalAnswered += 1
        if isCorrect {
            score += 1
        }
        
        // Update SRS
        updateSRSProgress(flashcard: flashcard, isCorrect: isCorrect)
        
        // Record mistake if wrong
        if !isCorrect {
            DatabaseManager.shared.recordMistake(
                flashcardId: flashcard.id,
                practiceType: "Speaking",
                topicId: topicId
            )
        }
        
        // Play sound
        if isCorrect {
            SoundManager.shared.playCorrectWithHaptic()
        } else {
            SoundManager.shared.playIncorrectWithHaptic()
        }
        
        withAnimation(.spring()) {
            showResult = true
        }
    }
    
    private func showTextInputDialog(completion: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Gõ đáp án thay cho nói"
        alert.informativeText = "Trên macOS không hỗ trợ nhận diện giọng nói. Gõ đáp án (câu bạn vừa đọc) để kiểm tra."

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 400, height: 24))
        input.placeholderString = "Gõ đáp án..."
        alert.accessoryView = input
        alert.addButton(withTitle: "Xác nhận")
        alert.addButton(withTitle: "Hủy")
        
        alert.window.initialFirstResponder = input
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            completion(input.stringValue)
        } else {
            isRecording = false
            completion("")
        }
    }

    private func nextCard() {
        if let url = lastRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        lastRecordingURL = nil
        playbackPlayer = nil
        withAnimation(.spring()) {
            currentIndex += 1
            showResult = false
            recognizedText = ""
            isCorrect = false
        }
    }

    private func playLastRecording() {
        guard let url = lastRecordingURL else { return }
        playbackPlayer?.stop()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            playbackPlayer = player
            player.play()
        } catch {
            // Ignore playback error
        }
    }

    private func updateSRSProgress(flashcard: Flashcard, isCorrect: Bool) {
        var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: flashcard.id) ?? 
            FlashcardProgress(flashcardId: flashcard.id)
        
        let quality: Double = isCorrect ? 1.0 : 0.0
        progress = srsAlgorithm.calculateNextReview(progress: progress, quality: quality)
        DatabaseManager.shared.saveFlashcardProgress(progress)
    }
}

