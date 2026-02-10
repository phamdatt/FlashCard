//
//  SimilarLookingData.swift
//  flash-card
//
//  Các nhóm chữ Hán có hình dáng tương tự, dễ nhầm lẫn. Dữ liệu lấy từ database (bảng similar_looking_groups).
//

import Foundation

enum SimilarLookingData {
    /// Kiểm tra chuỗi có chứa ít nhất một ký tự thuộc nhóm dễ nhầm không (đọc từ DB).
    static func hasSimilarLookingCharacter(_ text: String) -> Bool {
        let allCharacters = DatabaseManager.shared.getSimilarLookingCharacters()
        return text.contains { allCharacters.contains($0) }
    }

    /// Lấy các nhóm có chứa ít nhất một ký tự trong `text` (đọc từ DB).
    static func groupsOverlapping(with text: String) -> [Set<Character>] {
        let groups = DatabaseManager.shared.getSimilarLookingGroups()
        var result: [Set<Character>] = []
        let textSet = Set(text)
        for group in groups {
            let groupSet = Set(group)
            if !textSet.isDisjoint(with: groupSet) {
                result.append(groupSet)
            }
        }
        return result
    }

    /// Kiểm tra `candidate` có chứa ký tự từ một trong các `groups` không (và khác `excludeText`).
    static func isInSameGroupAs(candidate: String, groups: [Set<Character>], excludeText: String) -> Bool {
        guard candidate != excludeText else { return false }
        let candidateSet = Set(candidate)
        for group in groups {
            if !candidateSet.isDisjoint(with: group) {
                return true
            }
        }
        return false
    }
}
