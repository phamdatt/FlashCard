# FlashCard

Ung dung macOS ho tro hoc tu vung da ngon ngu (Anh-Viet, Trung) voi nhieu che do luyen tap khac nhau.

## Tinh nang chinh

- **Flashcard truyen thong** - Lat the voi hieu ung animation, hien thi cau hoi/tra loi/goi y
- **Trac nghiem** - 4 lua chon voi phan hoi tuc thi, theo doi diem so va ti le dung
- **Doc hieu** - Bai doc theo cap do (Beginner -> Advanced) kem cau hoi va tu vung ho tro
- **Quan ly noi dung** - Them/xoa chu de, flashcard tuy chinh
- **Tim kiem** - Loc chu de nhanh theo tu khoa

## Cong nghe

| Thanh phan | Cong nghe |
|---|---|
| Framework | SwiftUI |
| Ngon ngu | Swift |
| Co so du lieu | SQLite3 |
| Kien truc | MVVM |
| State Management | Combine |

## Cau truc du an

```
flash-card/
├── flash_cardApp.swift          # Entry point
├── Models.swift                 # Data models (Subject, Topic, Flashcard, ReadingPassage...)
├── ContentView.swift            # UI chinh - NavigationSplitView 3 cot
├── ContentViewModel.swift       # ViewModel - xu ly logic va state
├── FlashcardMainView.swift      # Giao dien hoc flashcard (List/Practice/Reading)
├── DatabaseManager.swift        # Quan ly SQLite, seed du lieu tu CSV
├── Data/
│   └── flashcards.sqlite        # Co so du lieu SQLite
├── Assets.xcassets/             # Icon va tai nguyen
└── LearnMacOS.xcdatamodel       # Core Data schema (legacy)
```

## Mo hinh du lieu

```
Subject (Chu de lon)
  └── Topic (Chu de con)
        ├── Flashcard (The hoc)
        │     └── Exercise Types: Dich Anh→Viet, Viet→Anh, Dien tu, Chon tu dung, Ghep nghia
        └── ReadingPassage (Bai doc hieu)
              ├── ReadingQuestion (Cau hoi trac nghiem)
              └── VocabularyItem (Tu vung ho tro)
```

## Giao dien

Ung dung su dung **NavigationSplitView** 3 cot:

1. **Sidebar** - Danh sach chu de lon (Vocabulary, IELTS, Chinese...)
2. **Cot giua** - Danh sach topic voi thanh tim kiem
3. **Chi tiet** - 3 che do hien thi:
   - **List** - Xem danh sach flashcard va chi tiet
   - **Practice** - Luyen tap co tinh gio, chon so luong tu (20/40/60/All)
   - **Reading** - Doc hieu theo cap do

## Du lieu co san

- Tu vung co ban: gia dinh, mua, mau sac, ngay, do an, trai cay, dong vat, co the, quan ao, thoi tiet...
- Ngay le: Christmas, Tet
- IELTS: moi truong, cong nghe, suc khoe, giao duc, xa hoi, tinh cach
- IT vocabulary
- Tieng Trung: gia dinh, mau sac, bo thu, HSK3

## Yeu cau he thong

- macOS
- Xcode

## Cai dat & Chay

```bash
# Clone repository
git clone <repository-url>

# Mo project bang Xcode
open flash-card.xcodeproj

# Build va chay (Cmd + R)
```

Du lieu se duoc tu dong seed vao SQLite khi chay lan dau tien.
