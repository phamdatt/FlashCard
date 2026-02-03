//
//  PersistenceController.swift
//  learn-macos
//
//  Created by Dat Pham on 1/2/26.
//

import Foundation

/// Simple persistence using UserDefaults (like localStorage)
struct PersistenceController {
    static let shared = PersistenceController()
    
    private let defaults = UserDefaults.standard
    private let subjectsKey = "saved_subjects"
    
    // MARK: - Subject Operations
    
    func saveSubjects(_ subjects: [Subject]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(subjects)
            defaults.set(data, forKey: subjectsKey)
            defaults.synchronize() // Force save immediately
            print("✅ Saved \(subjects.count) subjects to UserDefaults")
        } catch {
            print("❌ Failed to save subjects: \(error.localizedDescription)")
        }
    }
    
    func loadSubjects() -> [Subject]? {
        guard let data = defaults.data(forKey: subjectsKey) else {
            print("📦 No saved data found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let subjects = try decoder.decode([Subject].self, from: data)
            print("✅ Loaded \(subjects.count) subjects from UserDefaults")
            return subjects
        } catch {
            print("❌ Failed to load subjects: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteAllData() {
        defaults.removeObject(forKey: subjectsKey)
        defaults.synchronize()
        print("🗑️ Deleted all data")
    }
    
    func hasData() -> Bool {
        return defaults.data(forKey: subjectsKey) != nil
    }
}
