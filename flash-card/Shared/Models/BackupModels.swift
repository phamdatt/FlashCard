//
//  BackupModels.swift
//  flash-card
//
//  Codable structures for backup export/import (user-created data only).
//

import Foundation

struct BackupPayload: Codable {
    let version: Int
    let exportedAt: String
    let subjects: [ExportSubject]
}

struct ExportSubject: Codable {
    let id: Int
    let name: String
    let icon: String
    let topics: [ExportTopic]
}

struct ExportTopic: Codable {
    let name: String
    let flashcards: [ExportFlashcard]
    let readings: [ExportReading]
}

struct ExportFlashcard: Codable {
    let question: String
    let answer: String
    let hint: String?
    let exerciseType: String
}

struct ExportReading: Codable {
    let title: String
    let content: String
}
