//
//  DBError.swift
//  flash-card
//
//  Standard errors from DatabaseManager; ViewModels catch and show errorMessage.
//

import Foundation

/// Errors when operating on SQLite / DatabaseManager.
enum DBError: LocalizedError {
    case databaseNotOpen
    case openFailed(String)
    case prepareFailed(String)
    case stepFailed(String)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotOpen:
            return "Cơ sở dữ liệu chưa mở."
        case .openFailed(let msg):
            return "Không mở được cơ sở dữ liệu: \(msg)"
        case .prepareFailed(let msg):
            return "Lỗi chuẩn bị truy vấn: \(msg)"
        case .stepFailed(let msg):
            return "Lỗi thực thi: \(msg)"
        case .message(let msg):
            return msg
        }
    }
}
