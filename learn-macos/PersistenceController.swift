//
//  PersistenceController.swift
//  learn-macos
//
//  Created by Dat Pham on 1/2/26.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LearnMacOS")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Save context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Subject Operations
    
    func saveSubject(_ subject: Subject) {
        let context = container.viewContext
        let entity = SubjectEntity(context: context)
        
        entity.id = subject.id
        entity.name = subject.name
        entity.icon = subject.icon
        
        // Save topics
        for topic in subject.topics {
            let topicEntity = TopicEntity(context: context)
            topicEntity.id = topic.id
            topicEntity.name = topic.name
            topicEntity.subjectName = topic.subjectName
            topicEntity.subject = entity
            
            // Save flashcards
            for flashcard in topic.flashcards {
                let flashcardEntity = FlashcardEntity(context: context)
                flashcardEntity.id = flashcard.id
                flashcardEntity.question = flashcard.question
                flashcardEntity.answer = flashcard.answer
                flashcardEntity.hint = flashcard.hint
                flashcardEntity.options = flashcard.options
                flashcardEntity.correctAnswer = flashcard.correctAnswer
                flashcardEntity.exerciseType = flashcard.exerciseType.rawValue
                flashcardEntity.topic = topicEntity
            }
        }
        
        save()
    }
    
    func fetchSubjects() -> [Subject] {
        let context = container.viewContext
        let request = NSFetchRequest<SubjectEntity>(entityName: "SubjectEntity")
        
        do {
            let entities = try context.fetch(request)
            return entities.map { entity in
                Subject(
                    id: entity.id ?? UUID(),
                    name: entity.name ?? "",
                    icon: entity.icon ?? "book.fill",
                    topics: (entity.topics?.allObjects as? [TopicEntity])?.map { topicEntity in
                        Topic(
                            id: topicEntity.id ?? UUID(),
                            name: topicEntity.name ?? "",
                            subjectName: topicEntity.subjectName ?? "",
                            flashcards: (topicEntity.flashcards?.allObjects as? [FlashcardEntity])?.map { flashcardEntity in
                                Flashcard(
                                    id: flashcardEntity.id ?? UUID(),
                                    question: flashcardEntity.question ?? "",
                                    answer: flashcardEntity.answer ?? "",
                                    hint: flashcardEntity.hint,
                                    options: flashcardEntity.options,
                                    correctAnswer: flashcardEntity.correctAnswer,
                                    exerciseType: ExerciseType(rawValue: flashcardEntity.exerciseType ?? "") ?? .englishToVietnamese
                                )
                            } ?? []
                        )
                    } ?? []
                )
            }
        } catch {
            print("Failed to fetch subjects: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteAllData() {
        let context = container.viewContext
        
        // Delete all subjects
        let subjectRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SubjectEntity")
        let subjectDelete = NSBatchDeleteRequest(fetchRequest: subjectRequest)
        
        // Delete all topics
        let topicRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TopicEntity")
        let topicDelete = NSBatchDeleteRequest(fetchRequest: topicRequest)
        
        // Delete all flashcards
        let flashcardRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FlashcardEntity")
        let flashcardDelete = NSBatchDeleteRequest(fetchRequest: flashcardRequest)
        
        do {
            try context.execute(flashcardDelete)
            try context.execute(topicDelete)
            try context.execute(subjectDelete)
            save()
        } catch {
            print("Failed to delete data: \(error.localizedDescription)")
        }
    }
}
