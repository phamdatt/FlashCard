//
//  flash_cardTests.swift
//  flash-cardTests
//
//  Created by Dat Pham on 29/1/26.
//
//  Phase 4: C1 ViewModel tests, C2 DatabaseManager tests (in-memory).
//

import Testing
@testable import flash_card

// MARK: - C2 – Unit test DatabaseManager (in-memory)
struct DatabaseManagerTests {

    @Test func inMemory_insertTopic_insertFlashcard_loadSubjects_returnsCountAndContent() throws {
        let db = DatabaseManager(inMemoryForTesting: true)
        let topic = Topic(name: "Test Topic", subjectId: 1, flashcards: [], readings: [])
        let topicId = try db.insertTopic(topic)
        #expect(topicId > 0)

        let card = Flashcard(
            question: "Q1",
            answer: "A1",
            hint: nil,
            options: nil,
            correctAnswer: nil,
            exerciseType: Flashcard.exerciseTypeLabel
        )
        try db.insertFlashcard(card, topicId: topicId)

        let subjects = db.loadAllSubjects()
        #expect(subjects.count == 1)
        #expect(subjects[0].name == "Test")
        #expect(subjects[0].topics.count == 1)
        #expect(subjects[0].topics[0].name == "Test Topic")
        #expect(subjects[0].topics[0].flashcards.count == 1)
        #expect(subjects[0].topics[0].flashcards[0].question == "Q1")
        #expect(subjects[0].topics[0].flashcards[0].answer == "A1")
    }

    @Test func inMemory_updateFlashcard_deleteFlashcard_work() throws {
        let db = DatabaseManager(inMemoryForTesting: true)
        let topic = Topic(name: "T", subjectId: 1, flashcards: [], readings: [])
        let topicId = try db.insertTopic(topic)
        let card = Flashcard(question: "Q", answer: "A", hint: nil, options: nil, correctAnswer: nil, exerciseType: Flashcard.exerciseTypeLabel)
        try db.insertFlashcard(card, topicId: topicId)

        let subjectsBefore = db.loadAllSubjects()
        let flashcardId = subjectsBefore[0].topics[0].flashcards[0].id

        try db.updateFlashcard(id: flashcardId, question: "Q2", answer: "A2", hint: nil)
        let afterUpdate = db.loadAllSubjects()
        #expect(afterUpdate[0].topics[0].flashcards[0].question == "Q2")

        try db.deleteFlashcard(id: flashcardId)
        let afterDelete = db.loadAllSubjects()
        #expect(afterDelete[0].topics[0].flashcards.isEmpty)
    }
}

// MARK: - C1 – Unit test ContentViewModel (filteredTopics, selectSubject, addTopic, addFlashcard, updateFlashcard)
@MainActor
struct ContentViewModelTests {

    @Test func filteredTopics_filtersBySearchText() async {
        let db = DatabaseManager(inMemoryForTesting: true)
        let topic1 = Topic(name: "Apple", subjectId: 1, flashcards: [], readings: [])
        let topic2 = Topic(name: "Banana", subjectId: 1, flashcards: [], readings: [])
        _ = try? db.insertTopic(topic1)
        _ = try? db.insertTopic(topic2)

        let viewModel = ContentViewModel(databaseForTesting: db)
        viewModel.loadLearningData()
        #expect(viewModel.subjects.count == 1)
        let subject = viewModel.subjects[0]
        #expect(subject.topics.count == 2)

        viewModel.searchText = "App"
        let filtered = viewModel.filteredTopics(for: subject)
        #expect(filtered.count == 1)
        #expect(filtered[0].name == "Apple")

        viewModel.searchText = ""
        #expect(viewModel.filteredTopics(for: subject).count == 2)
    }

    @Test func selectSubject_addTopic_addFlashcard_updateFlashcard() async throws {
        let db = DatabaseManager(inMemoryForTesting: true)
        let viewModel = ContentViewModel(databaseForTesting: db)
        viewModel.loadLearningData()
        #expect(viewModel.subjects.count == 1)
        viewModel.selectSubject(viewModel.subjects[0])
        #expect(viewModel.selectedSubject?.name == "Test")

        viewModel.addTopic(name: "My Topic")
        viewModel.loadLearningData()
        viewModel.selectSubject(viewModel.subjects[0])
        let topic = viewModel.subjects[0].topics.first { $0.name == "My Topic" }
        #expect(topic != nil)
        viewModel.selectTopic(topic!)

        viewModel.addFlashcard(question: "Hello", answer: "Xin chào", hint: "")
        viewModel.loadLearningData()
        viewModel.selectSubject(viewModel.subjects[0])
        viewModel.selectTopic(viewModel.subjects[0].topics.first { $0.name == "My Topic" }!)
        let fc = viewModel.selectedTopic?.flashcards.first { $0.question == "Hello" }
        #expect(fc != nil)

        if let flashcard = fc {
            viewModel.selectFlashcard(flashcard)
            viewModel.updateFlashcard(id: flashcard.id, question: "Hi", answer: "Chào", hint: nil)
            viewModel.loadLearningData()
            viewModel.selectTopic(viewModel.subjects[0].topics.first { $0.name == "My Topic" }!)
            let updated = viewModel.selectedTopic?.flashcards.first { $0.id == flashcard.id }
            #expect(updated?.question == "Hi")
        }
    }
}
