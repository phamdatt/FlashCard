//
//  TopicSheets.swift
//  flash-card
//
//  Add Topic và Rename Topic sheet.
//

import SwiftUI

// MARK: - Add Topic Sheet
struct AddTopicSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Tạo chủ đề mới")
                    .font(.app(.title2))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    viewModel.newTopicName = ""
                    viewModel.showAddTopicSheet = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.app(.title2))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }

            if let subject = viewModel.selectedSubject {
                HStack(spacing: 8) {
                    Image(systemName: subject.displayIcon)
                        .foregroundStyle(.secondary)
                    Text(subject.name)
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            ThemeDivider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Tên chủ đề")
                    .font(.app(.headline))
                    .foregroundStyle(.primary)
                TextField("Ví dụ: Sports (Thể thao)", text: $viewModel.newTopicName)
                    .textFieldStyle(.roundedBorder)
                    .font(.app(.body))
                    .focused($isFocused)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.newTopicName = ""
                    viewModel.showAddTopicSheet = false
                }) {
                    Text("Huỷ")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
                .cursor(.pointingHand)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                Button(action: {
                    viewModel.addTopic(name: viewModel.newTopicName)
                }) {
                    Text("Tạo chủ đề")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.newTopicName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(.accentColor)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 400, height: 280)
        .background(colorScheme == .dark ? Color.appPopupBackgroundDark : Color.appBackgroundPage(isLight: true))
        .onAppear { isFocused = true }
    }
}

// MARK: - Rename Topic Sheet
struct RenameTopicSheet: View {
    @ObservedObject var viewModel: ContentViewModel
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Sửa tên chủ đề")
                    .font(.app(.title2))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    viewModel.topicToRename = nil
                    viewModel.renameTopicName = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.app(.title2))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .cursor(.pointingHand)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tên chủ đề")
                    .font(.app(.headline))
                    .foregroundStyle(.primary)
                TextField("Tên chủ đề", text: $viewModel.renameTopicName)
                    .textFieldStyle(.roundedBorder)
                    .font(.app(.body))
                    .focused($isFocused)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    viewModel.topicToRename = nil
                    viewModel.renameTopicName = ""
                }) {
                    Text("Huỷ")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
                .cursor(.pointingHand)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
                Button(action: { viewModel.renameTopic() }) {
                    Text("Lưu")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .keyboardShortcut(.return)
                .disabled(viewModel.renameTopicName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .cursor(.pointingHand)
                .tint(.accentColor)
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(width: 400, height: 240)
        .background(colorScheme == .dark ? Color.appPopupBackgroundDark : Color.appBackgroundPage(isLight: true))
        .onAppear { isFocused = true }
    }
}
