//
//  flash_cardApp.swift
//  flash-card
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import Combine

// MARK: - Appearance Manager
enum AppearanceMode: String, CaseIterable {
    case auto = "Tự động"
    case light = "Sáng"
    case dark = "Tối"

    var icon: String {
        switch self {
        case .auto: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    func next() -> AppearanceMode {
        switch self {
        case .auto: return .light
        case .light: return .dark
        case .dark: return .auto
        }
    }
}

class AppearanceManager: ObservableObject {
    @Published var mode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
            applyAppearance()
        }
    }

    private var timer: Timer?

    init() {
        let saved = UserDefaults.standard.string(forKey: "appearanceMode") ?? AppearanceMode.auto.rawValue
        self.mode = AppearanceMode(rawValue: saved) ?? .auto
        applyAppearance()
        startAutoTimer()
    }

    func cycleMode() {
        mode = mode.next()
    }

    private func startAutoTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self, self.mode == .auto else { return }
            DispatchQueue.main.async {
                self.applyAppearance()
            }
        }
    }

    private func applyAppearance() {
        let appearance: NSAppearance?
        switch mode {
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            let isDaytime = hour >= 6 && hour < 18
            appearance = NSAppearance(named: isDaytime ? .aqua : .darkAqua)
        }
        NSApp.appearance = appearance
    }
}

private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

@main
struct flash_cardApp: App {
    @StateObject private var appearanceManager = AppearanceManager()
    @StateObject private var fontSizeManager = FontSizeManager()
    @AppStorage(hasCompletedOnboardingKey) private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                    })
                }
            }
            .environmentObject(appearanceManager)
            .environmentObject(fontSizeManager)
            .applyGlobalFontSize(fontSizeManager: fontSizeManager)
        }
        .commands {
            CommandGroup(after: .textEditing) {
                Divider()
                
                Button("Tăng kích thước chữ") {
                    fontSizeManager.increaseFontSize()
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Giảm kích thước chữ") {
                    fontSizeManager.decreaseFontSize()
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Đặt lại kích thước chữ") {
                    fontSizeManager.resetFontSize()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            CommandGroup(after: .help) {
                Button("Phím tắt") {
                    NotificationCenter.default.post(name: .openKeyboardShortcuts, object: nil)
                }
            }
        }
    }
}
