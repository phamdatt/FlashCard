import Foundation

struct Subject: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let icon: String
    var topics: [Topic]

    init(id: Int, name: String, icon: String, topics: [Topic]) {
        self.id = id
        self.name = name
        self.icon = icon
        self.topics = topics
    }
}

struct Topic: Identifiable, Hashable, Codable {
    var id: Int
    var name: String
    var subjectId: Int
    var flashcards: [Flashcard]
    var readings: [ReadingPassage]

    init(
         id: Int = 0,
         name: String,
         subjectId: Int,
         flashcards: [Flashcard],
         readings: [ReadingPassage] = []) {

        self.id = id
        self.name = name
        self.subjectId = subjectId
        self.flashcards = flashcards
        self.readings = readings
    }
}

struct Flashcard: Identifiable, Hashable, Codable {
    let id: Int
    let question: String
    let answer: String
    let hint: String?
    let options: [String]?
    let correctAnswer: String?
    let exerciseType: ExerciseType

    var isMultipleChoice: Bool {
        options != nil && correctAnswer != nil
    }

    init(id: Int = 0, question: String, answer: String, hint: String? = nil, options: [String]? = nil, correctAnswer: String? = nil, exerciseType: ExerciseType) {
        self.id = id
        self.question = question
        self.answer = answer
        self.hint = hint
        self.options = options
        self.correctAnswer = correctAnswer
        self.exerciseType = exerciseType
    }
}

// MARK: - Reading Passage Models
struct ReadingPassage: Identifiable, Hashable, Codable {
    let id: Int // Đã đổi từ UUID -> Int
    let title: String
    let level: ReadingLevel
    let content: String
    let questions: [ReadingQuestion]
    let vocabularyHelp: [VocabularyItem]?

    init(id: Int, title: String, level: ReadingLevel, content: String, questions: [ReadingQuestion], vocabularyHelp: [VocabularyItem]? = nil) {
        self.id = id
        self.title = title
        self.level = level
        self.content = content
        self.questions = questions
        self.vocabularyHelp = vocabularyHelp
    }
}

struct ReadingQuestion: Identifiable, Hashable, Codable {
    let id: Int // Đã đổi từ UUID -> Int
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String?

    init(id: Int, question: String, options: [String], correctAnswer: String, explanation: String? = nil) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

struct VocabularyItem: Identifiable, Hashable, Codable {
    let id: Int // Đã đổi từ UUID -> Int
    let word: String
    let meaning: String
    let example: String?

    init(id: Int, word: String, meaning: String, example: String? = nil) {
        self.id = id
        self.word = word
        self.meaning = meaning
        self.example = example
    }
}

enum ExerciseType: String, Hashable, Codable {
    case englishToVietnamese = "Dịch Anh → Việt"
    case vietnameseToEnglish = "Dịch Việt → Anh"
    case fillInTheBlank = "Điền từ vào chỗ trống"
    case chooseCorrectWord = "Chọn từ đúng"
    case matchMeaning = "Ghép nghĩa"
}

enum ReadingLevel: String, Hashable, Codable {
    case beginner = "Cơ bản"
    case elementary = "Sơ cấp"
    case intermediate = "Trung cấp"
    case upperIntermediate = "Trung cấp cao"
    case advanced = "Nâng cao"
}

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let didPracticeToday: Bool
}