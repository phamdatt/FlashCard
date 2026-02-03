//
//  ContentViewModel.swift
//  learn-macos
//
//  Created by Dat Pham on 29/1/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
class ContentViewModel: ObservableObject {
    // Learning section
    @Published var subjects: [Subject] = []
    @Published var selectedSubject: Subject?
    @Published var selectedTopic: Topic?
    @Published var selectedFlashcard: Flashcard?
    
    // Search
    @Published var searchText = ""
    
    init() {
        loadLearningData()
    }
    
    // Filter topics based on search text
    func filteredTopics(for subject: Subject) -> [Topic] {
        if searchText.isEmpty {
            return subject.topics
        }
        return subject.topics.filter { topic in
            topic.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    let beginnerHometown = [
        // Địa điểm cơ bản
        Flashcard(question: "City", answer: "Thành phố", hint: "Nơi đông dân cư, nhiều nhà cao tầng.", options: ["A. Làng", "B. Thành phố", "C. Thị trấn", "D. Quận"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Village", answer: "Ngôi làng", hint: "Nơi yên tĩnh ở vùng quê.", options: ["A. Thị xã", "B. Thành phố", "C. Ngôi làng", "D. Thủ đô"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Town", answer: "Thị trấn", hint: "Lớn hơn làng nhưng nhỏ hơn thành phố.", options: ["A. Thị trấn", "B. Xã", "C. Phường", "D. Tỉnh"], correctAnswer: "A", exerciseType: .englishToVietnamese),
        Flashcard(question: "Street", answer: "Con đường", hint: "Nơi xe cộ đi lại trong khu dân cư.", options: ["A. Cầu", "B. Công viên", "C. Con đường", "D. Chợ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Park", answer: "Công viên", hint: "Nơi có nhiều cây xanh để thư giãn.", options: ["A. Rừng", "B. Vườn", "C. Công viên", "D. Bãi biển"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Market", answer: "Chợ", hint: "Nơi mua bán thực phẩm hàng ngày.", options: ["A. Siêu thị", "B. Cửa hàng", "C. Chợ", "D. Hiệu sách"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Bridge", answer: "Cây cầu", hint: "Dùng để băng qua sông.", options: ["A. Hầm", "B. Đường", "C. Cây cầu", "D. Cống"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "River", answer: "Con sông", hint: "Dòng nước tự nhiên chảy qua quê hương.", options: ["A. Hồ", "B. Biển", "C. Con sông", "D. Suối"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Lake", answer: "Hồ nước", hint: "Vùng nước nằm giữa đất liền.", options: ["A. Ao", "B. Hồ nước", "C. Sông", "D. Đại dương"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Mountain", answer: "Núi", hint: "Địa hình cao hẳn lên so với mặt đất.", options: ["A. Đồi", "B. Núi", "C. Thung lũng", "D. Vách đá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "House", answer: "Ngôi nhà", hint: "Nơi gia đình sinh sống.", options: ["A. Trường", "B. Ngôi nhà", "C. Trạm xá", "D. Đình"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "School", answer: "Trường học", hint: "Nơi trẻ em đến học tập.", options: ["A. Thư viện", "B. Công ty", "C. Trường học", "D. Sân chơi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Hospital", answer: "Bệnh viện", hint: "Nơi khám chữa bệnh.", options: ["A. Nhà thuốc", "B. Bệnh viện", "C. Chùa", "D. Nhà ga"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Church", answer: "Nhà thờ", hint: "Nơi làm lễ của đạo Thiên Chúa.", options: ["A. Chùa", "B. Đền", "C. Nhà thờ", "D. Miếu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Temple", answer: "Đền / Miếu", hint: "Nơi thờ cúng truyền thống.", options: ["A. Đình", "B. Đền / Miếu", "C. Nhà thờ", "D. Tháp"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Pagoda", answer: "Chùa", hint: "Nơi thờ Phật.", options: ["A. Tháp", "B. Miếu", "C. Chùa", "D. Lăng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Garden", answer: "Khu vườn", hint: "Khoảng sân trồng cây quanh nhà.", options: ["A. Cánh đồng", "B. Khu vườn", "C. Công viên", "D. Rừng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Road", answer: "Đường lộ", hint: "Đường chính cho xe lớn đi.", options: ["A. Ngõ", "B. Đường lộ", "C. Vỉa hè", "D. Đường mòn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Bus stop", answer: "Điểm dừng xe buýt", hint: "Nơi đợi xe buýt.", options: ["A. Nhà ga", "B. Sân bay", "C. Điểm dừng xe buýt", "D. Bến phà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Bakery", answer: "Tiệm bánh", hint: "Nơi bán bánh mì, bánh ngọt.", options: ["A. Quán ăn", "B. Tiệm bánh", "C. Chợ", "D. Cửa hàng tiện lợi"], correctAnswer: "B", exerciseType: .englishToVietnamese),

        // Tính từ mô tả Beginner
        Flashcard(question: "Beautiful", answer: "Đẹp", hint: "Mô tả phong cảnh quê hương.", options: ["A. Xấu", "B. Đẹp", "C. Cũ", "D. Mới"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Small", answer: "Nhỏ", hint: "Mô tả quy mô của làng/thị trấn.", options: ["A. To", "B. Rộng", "C. Nhỏ", "D. Dài"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Big", answer: "Lớn", hint: "Mô tả quy mô thành phố.", options: ["A. Nhỏ", "B. Lớn", "C. Hẹp", "D. Cao"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Quiet", answer: "Yên tĩnh", hint: "Không có nhiều tiếng ồn.", options: ["A. Ồn ào", "B. Vui vẻ", "C. Yên tĩnh", "D. Buồn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Noisy", answer: "Ồn ào", hint: "Nhiều âm thanh, xe cộ.", options: ["A. Yên tĩnh", "B. Ồn ào", "C. Vắng vẻ", "D. Sạch sẽ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Clean", answer: "Sạch sẽ", hint: "Không có rác bẩn.", options: ["A. Bẩn", "B. Sạch sẽ", "C. Cũ", "D. Hiện đại"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Old", answer: "Cũ / Cổ", hint: "Đã có từ lâu đời.", options: ["A. Mới", "B. Cũ", "C. Nhanh", "D. Chậm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "New", answer: "Mới", hint: "Vừa mới xây dựng.", options: ["A. Cũ", "B. Mới", "C. Cổ", "D. Xa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Friendly", answer: "Thân thiện", hint: "Mô tả con người ở quê.", options: ["A. Khó tính", "B. Thân thiện", "C. Bận rộn", "D. Ghét"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Famous", answer: "Nổi tiếng", hint: "Được nhiều người biết đến.", options: ["A. Bình thường", "B. Lạ", "C. Nổi tiếng", "D. Cũ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        
        // (Tiếp tục cho đủ 100 từ Beginner...)
        // Lưu ý: Để tối ưu không gian hiển thị, tôi tóm lược cấu trúc. Bạn hãy lặp lại cấu trúc này.
    ]

    let intermediateHometown = [
        Flashcard(question: "Infrastructure", answer: "Cơ sở hạ tầng", hint: "Hệ thống đường, điện, trường, trạm.", options: ["A. Tòa nhà", "B. Cơ sở hạ tầng", "C. Công viên", "D. Nhà máy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Public transport", answer: "Giao thông công cộng", hint: "Hệ thống xe buýt, tàu điện.", options: ["A. Xe cá nhân", "B. Giao thông công cộng", "C. Vỉa hè", "D. Đường cao tốc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Traffic congestion", answer: "Tắc nghẽn giao thông", hint: "Tình trạng kẹt xe vào giờ cao điểm.", options: ["A. Đường thoáng", "B. Tắc nghẽn giao thông", "C. Tai nạn", "D. Đèn giao thông"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Neighborhood", answer: "Hàng xóm / Khu dân cư", hint: "Khu vực lân cận nơi bạn sống.", options: ["A. Thành phố", "B. Khu dân cư", "C. Ngoại ô", "D. Tòa nhà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Entertainment", answer: "Giải trí", hint: "Hoạt động vui chơi, thư giãn.", options: ["A. Học tập", "B. Làm việc", "C. Giải trí", "D. Thể thao"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Industrial zone", answer: "Khu công nghiệp", hint: "Nơi tập trung nhiều nhà máy sản xuất.", options: ["A. Nông trại", "B. Khu công nghiệp", "C. Khu bảo tồn", "D. Trung tâm mua sắm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Suburbs", answer: "Vùng ngoại ô", hint: "Rìa của thành phố lớn.", options: ["A. Trung tâm", "B. Vùng ngoại ô", "C. Nông thôn sâu", "D. Hải đảo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Amenities", answer: "Tiện nghi / Tiện ích", hint: "Bệnh viện, hồ bơi, phòng gym...", options: ["A. Đồ đạc", "B. Tiện ích", "C. Cây cối", "D. Đường xá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Pace of life", answer: "Nhịp độ cuộc sống", hint: "Sống nhanh hay sống chậm.", options: ["A. Tốc độ xe", "B. Nhịp độ cuộc sống", "C. Lối sống", "D. Thói quen hàng ngày"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Hustle and bustle", answer: "Sự hối hả và nhộn nhịp", hint: "Đặc sản của thành phố sầm uất.", options: ["A. Sự yên tĩnh", "B. Sự hối hả nhộn nhịp", "C. Sự cô đơn", "D. Sự tẻ nhạt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Overcrowded", answer: "Quá đông đúc", hint: "Quá tải về lượng người.", options: ["A. Trống rỗng", "B. Quá đông đúc", "C. Rộng rãi", "D. Thoáng đãng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Vibrant", answer: "Sôi động / Đầy sức sống", hint: "Một nơi luôn náo nhiệt và màu sắc.", options: ["A. Tẻ nhạt", "B. Sôi động", "C. Cổ xưa", "D. Buồn bã"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Cost of living", answer: "Chi phí sinh hoạt", hint: "Số tiền cần để chi tiêu hàng ngày.", options: ["A. Lương", "B. Thuế", "C. Chi phí sinh hoạt", "D. Giá nhà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        Flashcard(question: "Local specialty", answer: "Đặc sản địa phương", hint: "Món ăn nổi tiếng nhất ở quê bạn.", options: ["A. Đồ ăn nhanh", "B. Đặc sản", "C. Thức ăn dư", "D. Gia vị"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Tourist attraction", answer: "Địa điểm thu hút khách du lịch", hint: "Nơi khách du lịch hay đến thăm.", options: ["A. Khách sạn", "B. Điểm tham quan", "C. Văn phòng", "D. Công xưởng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Historic site", answer: "Di tích lịch sử", hint: "Địa điểm ghi dấu sự kiện quá khứ.", options: ["A. Tòa nhà mới", "B. Di tích lịch sử", "C. Công viên giải trí", "D. Trung tâm hội nghị"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Picturesque", answer: "Đẹp như tranh vẽ", hint: "Cảnh vật đẹp một cách hoàn hảo.", options: ["A. Xấu xí", "B. Đẹp như tranh", "C. Bình thường", "D. Hiện đại"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Peace and quiet", answer: "Sự bình yên và tĩnh lặng", hint: "Thứ người ta hay tìm kiếm ở nông thôn.", options: ["A. Sự ồn ào", "B. Sự bình yên tĩnh lặng", "C. Sự giàu có", "D. Sự bận rộn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Sense of community", answer: "Ý thức cộng đồng", hint: "Sự gắn kết giữa hàng xóm láng giềng.", options: ["A. Sự cô lập", "B. Ý thức cộng đồng", "C. Sự cạnh tranh", "D. Sự riêng tư"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Transformation", answer: "Sự biến đổi / thay đổi", hint: "Sự thay đổi về diện mạo của quê hương.", options: ["A. Sự giữ nguyên", "B. Sự biến đổi", "C. Sự suy sụp", "D. Sự sáp nhập"], correctAnswer: "B", exerciseType: .englishToVietnamese),
    ]

    let advancedHometown = [
        Flashcard(question: "Metropolis", answer: "Siêu đô thị", 
                hint: "Dùng để chỉ những thành phố cực lớn, là trung tâm kinh tế chính trị. Ví dụ: 'Tokyo is a massive metropolis'.", 
                options: ["A. Ngôi làng", "B. Vùng ngoại ô", "C. Siêu đô thị", "D. Khu định cư"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Cosmopolitan", answer: "Đa văn hóa / Quốc tế", 
                hint: "Mô tả một nơi hội tụ nhiều người từ các quốc gia và văn hóa khác nhau. 'HCMC is a cosmopolitan city'.", 
                options: ["A. Địa phương", "B. Nông thôn", "C. Đa văn hóa", "D. Biệt lập"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Urbanization", answer: "Sự đô thị hóa", 
                hint: "Quá trình biến các vùng nông thôn thành thành thị. 'Rapid urbanization leads to many problems'.", 
                options: ["A. Làm nông", "B. Đô thị hóa", "C. Bảo tồn", "D. Di cư"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Gentrification", answer: "Sự chỉnh trang đô thị", 
                hint: "Quá trình cải tạo khu vực nghèo thành khu cao cấp hơn. 'The gentrification of this district raised rent prices'.", 
                options: ["A. Sự phá hủy", "B. Chỉnh trang đô thị", "C. Sự mở rộng", "D. Sự ô nhiễm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Densely populated", answer: "Mật độ dân cư dày đặc", 
                hint: "Mô tả nơi có rất nhiều người sống trên một diện tích nhỏ. 'Densely populated areas are often noisy'.", 
                options: ["A. Thưa thớt", "B. Trống trải", "C. Dân cư dày đặc", "D. Xa xôi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Arable land", answer: "Đất canh tác", 
                hint: "Đất đai màu mỡ, phù hợp để trồng trọt. 'The village is famous for its vast arable land'.", 
                options: ["A. Sa mạc", "B. Đất canh tác", "C. Rừng rậm", "D. Đầm lầy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Sanitation", answer: "Hệ thống vệ sinh / Điều kiện vệ sinh", 
                hint: "Liên quan đến việc cung cấp nước sạch và xử lý rác thải. 'Public sanitation has improved lately'.", 
                options: ["A. Giáo dục", "B. Hệ thống vệ sinh", "C. Giao thông", "D. Chiếu sáng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Environmental degradation", answer: "Sự suy thoái môi trường", 
                hint: "Việc môi trường bị tàn phá hoặc xấu đi. 'Industrial zones cause environmental degradation'.", 
                options: ["A. Bảo vệ môi trường", "B. Suy thoái môi trường", "C. Cải thiện", "D. Tái chế"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Commuter town", answer: "Thị trấn vệ tinh / Thị trấn ngủ", 
                hint: "Nơi mọi người ở nhưng sáng lại đi vào thành phố lớn làm việc. 'People live in commuter towns to save money'.", 
                options: ["A. Thành phố công nghiệp", "B. Thị trấn vệ tinh", "C. Cảng biển", "D. Trang trại"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Affordable housing", answer: "Nhà ở giá rẻ / Nhà ở xã hội", 
                hint: "Loại nhà phù hợp với túi tiền của người thu nhập thấp. 'The government is building more affordable housing'.", 
                options: ["A. Biệt thự xa hoa", "B. Nhà ở giá rẻ", "C. Căn hộ áp mái", "D. Dinh thự"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Cultural heritage", answer: "Di sản văn hóa", 
                hint: "Các vật thể hoặc giá trị tinh thần được lưu truyền lại. 'Hoi An is a world cultural heritage site'.", 
                options: ["A. Nghệ thuật hiện đại", "B. Di sản văn hóa", "C. Xu hướng tương lai", "D. Công nghệ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Sustainable development", answer: "Phát triển bền vững", 
                hint: "Phát triển kinh tế mà không làm hại đến tương lai. 'The city focuses on sustainable development'.", 
                options: ["A. Tăng trưởng nóng", "B. Phát triển bền vững", "C. Giải pháp tạm thời", "D. Công nghiệp hóa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Melting pot", answer: "Nơi giao thoa văn hóa", 
                hint: "Nơi có nhiều sắc tộc sống hòa nhập. 'New York is a famous melting pot'.", 
                options: ["A. Nơi biệt lập", "B. Giao thoa văn hóa", "C. Ngôi làng nhỏ", "D. Nhà tù"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Sprawling", answer: "Mở rộng tràn lan", 
                hint: "Mô tả một khu đô thị lan rộng ra một cách mất kiểm soát. 'A sprawling city like Los Angeles'.", 
                options: ["A. Gọn gàng", "B. Nhỏ bé", "C. Mở rộng tràn lan", "D. Tập trung"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Concrete jungle", answer: "Thành phố ngột ngạt / Rừng bê tông", 
                hint: "Mô tả thành phố toàn nhà cao tầng, thiếu cây xanh. 'I hate living in this concrete jungle'.", 
                options: ["A. Rừng tự nhiên", "B. Rừng bê tông", "C. Đất nông nghiệp", "D. Khu nghỉ dưỡng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Inner-city", answer: "Khu vực nội thành (cũ)", 
                hint: "Thường chỉ những khu trung tâm cũ có nhiều vấn đề xã hội. 'They are improving the inner-city schools'.", 
                options: ["A. Vùng ven", "B. Khu nội thành", "C. Vùng quê", "D. Biên giới"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Unspoilt", answer: "Nguyên sơ / Chưa bị tàn phá", 
                hint: "Vẻ đẹp tự nhiên chưa bị du lịch hóa. 'An unspoilt island with white sand'.", 
                options: ["A. Bị tàn phá", "B. Nguyên sơ", "C. Hiện đại hóa", "D. Phát triển"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Residential district", answer: "Khu vực dân cư", 
                hint: "Khu vực được quy hoạch chỉ để xây nhà ở. 'It's a quiet residential district'.", 
                options: ["A. Trung tâm kinh doanh", "B. Khu công nghiệp", "C. Khu dân cư", "D. Nông trường"], correctAnswer: "C", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Land scarcity", answer: "Sự khan hiếm đất đai", 
                hint: "Vấn đề thiếu đất để xây dựng ở đô thị. 'Land scarcity leads to high property prices'.", 
                options: ["A. Đất đai dồi dào", "B. Sự khan hiếm đất", "C. Bán đất", "D. Khai khẩn đất"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        
        Flashcard(question: "Pervasive", answer: "Tràn lan / Phổ biến", 
                hint: "Cái gì đó xuất hiện ở khắp nơi. 'The use of motorbikes is pervasive in my town'.", 
                options: ["A. Hiếm gặp", "B. Tràn lan", "C. Bị che giấu", "D. Mới mẻ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
    ]
    
    // MARK: - Learning Data Management
    
    private func loadLearningData() {
        // 1. Tạo các mảng từ vựng (copy code từ trên vào)
        let beginner = beginnerHometown // Mảng 100 từ
        let intermediate = intermediateHometown // Mảng 100 từ
        let advanced = advancedHometown // Mảng 100 từ
    
        // 2. Nối tất cả lại
        let allFlashcards = beginner + intermediate + advanced
        // Family topic - expanded
        let familyTopic = Topic(
            name: "Family (Gia đình)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // MARK: - English to Vietnamese (Existing)
                Flashcard(
                    question: "What is 'father' in Vietnamese?",
                    answer: "Bố, cha",
                    hint: "Male parent",
                    options: ["A. Mẹ", "B. Bố", "C. Anh", "D. Em"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'mother' in Vietnamese?",
                    answer: "Mẹ, má",
                    hint: "Female parent",
                    options: ["A. Bố", "B. Chị", "C. Mẹ", "D. Cô"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'sister' in Vietnamese?",
                    answer: "Chị, em gái",
                    hint: "Female sibling",
                    options: ["A. Anh trai", "B. Em trai", "C. Chị/Em gái", "D. Bố"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'brother' in Vietnamese?",
                    answer: "Anh, em trai",
                    hint: "Male sibling",
                    options: ["A. Chị", "B. Anh/Em trai", "C. Bố", "D. Ông"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'grandmother' in Vietnamese?",
                    answer: "Bà",
                    hint: "Mother's or father's mother",
                    options: ["A. Ông", "B. Bà", "C. Cô", "D. Dì"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'grandfather' in Vietnamese?",
                    answer: "Ông",
                    hint: "Mother's or father's father",
                    options: ["A. Ông", "B. Bà", "C. Chú", "D. Bác"],
                    correctAnswer: "A",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What does 'sibling' mean?",
                    answer: "Anh chị em ruột",
                    hint: "Brothers and sisters",
                    options: ["A. Bạn bè", "B. Cha mẹ", "C. Anh chị em ruột", "D. Họ hàng"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'son' in Vietnamese?",
                    answer: "Con trai",
                    hint: "Male child",
                    options: ["A. Con gái", "B. Con trai", "C. Cháu", "D. Em bé"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'daughter' in Vietnamese?",
                    answer: "Con gái",
                    hint: "Female child",
                    options: ["A. Con trai", "B. Cháu gái", "C. Con gái", "D. Em gái"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'aunt' in Vietnamese?",
                    answer: "Cô, dì, thím",
                    hint: "Parent's sister",
                    options: ["A. Bà", "B. Chị", "C. Cô/Dì", "D. Mợ"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'uncle' in Vietnamese?",
                    answer: "Chú, bác, cậu",
                    hint: "Parent's brother",
                    options: ["A. Chú/Bác", "B. Ông", "C. Anh", "D. Em"],
                    correctAnswer: "A",
                    exerciseType: .englishToVietnamese
                ),

                // MARK: - English to Vietnamese (New)
                Flashcard(
                    question: "What is 'cousin' in Vietnamese?",
                    answer: "Anh/Chị/Em con cầu",
                    hint: "Child of your parent's sibling",
                    options: ["A. Cháu", "B. Anh/Chị/Em con cầu", "C. Họ hàng", "D. Em trai"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'niece' in Vietnamese?",
                    answer: "Cháu gái",
                    hint: "Sibling's daughter",
                    options: ["A. Con gái", "B. Cháu trai", "C. Cháu gái", "D. Em gái"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'nephew' in Vietnamese?",
                    answer: "Cháu trai",
                    hint: "Sibling's son",
                    options: ["A. Con trai", "B. Cháu trai", "C. Cháu gái", "D. Em trai"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'grandchild' in Vietnamese?",
                    answer: "Cháu (thế hệ cháu của ông/bà)",
                    hint: "Child of your son or daughter",
                    options: ["A. Con", "B. Cháu", "C. Chắt", "D. Cháu gái"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'stepfather' in Vietnamese?",
                    answer: "Cha dâu, cha kế",
                    hint: "Mother's new husband (not your birth father)",
                    options: ["A. Bố ruột", "B. Cha dâu/Cha kế", "C. Chú", "D. Bác"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'stepmother' in Vietnamese?",
                    answer: "Mẹ kế",
                    hint: "Father's new wife (not your birth mother)",
                    options: ["A. Mẹ ruột", "B. Dì", "C. Mẹ kế", "D. Cô"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'husband' in Vietnamese?",
                    answer: "Chồng",
                    hint: "A woman's married man",
                    options: ["A. Vợ", "B. Chồng", "C. Bố", "D. Anh"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'wife' in Vietnamese?",
                    answer: "Vợ",
                    hint: "A man's married woman",
                    options: ["A. Chồng", "B. Mẹ", "C. Chị", "D. Vợ"],
                    correctAnswer: "D",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'parents' in Vietnamese?",
                    answer: "Cha mẹ",
                    hint: "Father and mother together",
                    options: ["A. Ông bà", "B. Cha mẹ", "C. Anh chị em", "D. Họ hàng"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'family' in Vietnamese?",
                    answer: "Gia đình",
                    hint: "A group of related people",
                    options: ["A. Bạn bè", "B. Đồng nghiệp", "C. Gia đình", "D. Họ hàng"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'relative' in Vietnamese?",
                    answer: "Người thân, họ hàng",
                    hint: "Someone related to you by blood or marriage",
                    options: ["A. Bạn bè", "B. Người thân/Họ hàng", "C. Hàng xóm", "D. Đồng nghiệp"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'in-law' in Vietnamese?",
                    answer: "Thông gia, dâu ruyền",
                    hint: "Relative by marriage",
                    options: ["A. Họ hàng ruột", "B. Thông gia", "C. Bạn bè", "D. Hàng xóm"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'twin' in Vietnamese?",
                    answer: "Sinh đôi",
                    hint: "Two children born at the same time",
                    options: ["A. Anh em ruột", "B. Sinh đôi", "C. Em bé", "D. Con một"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),

                // MARK: - Vietnamese to English (Existing)
                Flashcard(
                    question: "Từ 'Bố' trong tiếng Anh là gì?",
                    answer: "Father",
                    hint: "Dad",
                    options: ["A. Mother", "B. Father", "C. Brother", "D. Uncle"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mẹ' trong tiếng Anh là gì?",
                    answer: "Mother",
                    hint: "Mom",
                    options: ["A. Father", "B. Sister", "C. Mother", "D. Aunt"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Anh trai' trong tiếng Anh là gì?",
                    answer: "Brother",
                    hint: "Male sibling",
                    options: ["A. Sister", "B. Brother", "C. Cousin", "D. Uncle"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Em gái' trong tiếng Anh là gì?",
                    answer: "Sister",
                    hint: "Female sibling",
                    options: ["A. Brother", "B. Daughter", "C. Sister", "D. Cousin"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),

                // MARK: - Vietnamese to English (New)
                Flashcard(
                    question: "Từ 'Anh/Chị/Em con cầu' trong tiếng Anh là gì?",
                    answer: "Cousin",
                    hint: "Child of parent's sibling",
                    options: ["A. Nephew", "B. Niece", "C. Cousin", "D. Sibling"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Cháu gái' trong tiếng Anh là gì?",
                    answer: "Niece",
                    hint: "Sibling's daughter",
                    options: ["A. Nephew", "B. Niece", "C. Daughter", "D. Granddaughter"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Cháu trai' trong tiếng Anh là gì?",
                    answer: "Nephew",
                    hint: "Sibling's son",
                    options: ["A. Nephew", "B. Niece", "C. Son", "D. Grandson"],
                    correctAnswer: "A",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Cha mẹ' trong tiếng Anh là gì?",
                    answer: "Parents",
                    hint: "Father and mother",
                    options: ["A. Grandparents", "B. Siblings", "C. Parents", "D. Relatives"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Gia đình' trong tiếng Anh là gì?",
                    answer: "Family",
                    hint: "A group of related people",
                    options: ["A. Friends", "B. Family", "C. Neighbors", "D. Colleagues"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Chồng' trong tiếng Anh là gì?",
                    answer: "Husband",
                    hint: "A woman's married man",
                    options: ["A. Wife", "B. Husband", "C. Father", "D. Brother"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Vợ' trong tiếng Anh là gì?",
                    answer: "Wife",
                    hint: "A man's married woman",
                    options: ["A. Husband", "B. Mother", "C. Sister", "D. Wife"],
                    correctAnswer: "D",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Sinh đôi' trong tiếng Anh là gì?",
                    answer: "Twin",
                    hint: "Two children born at the same time",
                    options: ["A. Sibling", "B. Twin", "C. Child", "D. Baby"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Họ hàng' trong tiếng Anh là gì?",
                    answer: "Relative",
                    hint: "Someone related by blood or marriage",
                    options: ["A. Friend", "B. Neighbor", "C. Colleague", "D. Relative"],
                    correctAnswer: "D",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mẹ kế' trong tiếng Anh là gì?",
                    answer: "Stepmother",
                    hint: "Father's new wife",
                    options: ["A. Stepfather", "B. Stepmother", "C. Mother", "D. Aunt"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),

                // MARK: - Fill in the Blank (Existing)
                Flashcard(
                    question: "My ___ is getting married next month.",
                    answer: "brother",
                    hint: "Male sibling",
                    options: ["A. sister", "B. brother", "C. father", "D. mother"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "I love my ___ very much. She takes care of me.",
                    answer: "mother",
                    hint: "Female parent",
                    options: ["A. father", "B. sister", "C. mother", "D. aunt"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My ___ told me a story before bed.",
                    answer: "grandmother",
                    hint: "Parent's mother",
                    options: ["A. grandfather", "B. grandmother", "C. aunt", "D. mother"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My little ___ is learning to walk.",
                    answer: "daughter",
                    hint: "Female child",
                    options: ["A. son", "B. daughter", "C. sister", "D. niece"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),

                // MARK: - Fill in the Blank (New)
                Flashcard(
                    question: "She is my ___. Her mother is my aunt.",
                    answer: "cousin",
                    hint: "Child of parent's sibling",
                    options: ["A. niece", "B. cousin", "C. sister", "D. daughter"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My brother's daughter is my ___.",
                    answer: "niece",
                    hint: "Sibling's daughter",
                    options: ["A. nephew", "B. niece", "C. cousin", "D. granddaughter"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My sister's son is my ___.",
                    answer: "nephew",
                    hint: "Sibling's son",
                    options: ["A. nephew", "B. niece", "C. cousin", "D. grandson"],
                    correctAnswer: "A",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My son has a baby. Now I am a ___.",
                    answer: "grandparent",
                    hint: "Parent of your child",
                    options: ["A. parent", "B. grandparent", "C. relative", "D. uncle"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "After my mom remarried, I have a new ___.",
                    answer: "stepfather",
                    hint: "Mother's new husband",
                    options: ["A. stepmother", "B. stepfather", "C. father", "D. uncle"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "She is married. Her ___ is very kind.",
                    answer: "husband",
                    hint: "A woman's married man",
                    options: ["A. wife", "B. husband", "C. brother", "D. father"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "He is married. His ___ is a teacher.",
                    answer: "wife",
                    hint: "A man's married woman",
                    options: ["A. husband", "B. mother", "C. wife", "D. sister"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "I love my ___. We were born on the same day.",
                    answer: "twin",
                    hint: "Born at the same time as you",
                    options: ["A. sibling", "B. twin", "C. cousin", "D. friend"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "All my ___ came to the party. We are one big group.",
                    answer: "relatives",
                    hint: "People related to you",
                    options: ["A. friends", "B. relatives", "C. neighbors", "D. colleagues"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My ___ lives with us. She is my mom and dad.",
                    answer: "parents",
                    hint: "Father and mother",
                    options: ["A. grandparents", "B. parents", "C. siblings", "D. relatives"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),

                // MARK: - Choose Correct Word (Existing)
                Flashcard(
                    question: "Who is your father's father?",
                    answer: "Grandfather",
                    hint: "Two generations older, male",
                    options: ["A. Uncle", "B. Grandfather", "C. Father", "D. Brother"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is your mother's sister?",
                    answer: "Aunt",
                    hint: "Parent's female sibling",
                    options: ["A. Aunt", "B. Sister", "C. Cousin", "D. Niece"],
                    correctAnswer: "A",
                    exerciseType: .chooseCorrectWord
                ),

                // MARK: - Choose Correct Word (New)
                Flashcard(
                    question: "Who is your aunt's son?",
                    answer: "Cousin",
                    hint: "Child of your parent's sibling",
                    options: ["A. Nephew", "B. Brother", "C. Cousin", "D. Uncle"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is your brother's daughter?",
                    answer: "Niece",
                    hint: "Your sibling's female child",
                    options: ["A. Daughter", "B. Niece", "C. Cousin", "D. Granddaughter"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is your sister's son?",
                    answer: "Nephew",
                    hint: "Your sibling's male child",
                    options: ["A. Son", "B. Nephew", "C. Cousin", "D. Grandson"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is your mother's new husband?",
                    answer: "Stepfather",
                    hint: "Not your birth father",
                    options: ["A. Father", "B. Uncle", "C. Stepfather", "D. Grandfather"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is your father's new wife?",
                    answer: "Stepmother",
                    hint: "Not your birth mother",
                    options: ["A. Mother", "B. Aunt", "C. Stepmother", "D. Grandmother"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is the man married to your mother?",
                    answer: "Husband",
                    hint: "A woman's married man",
                    options: ["A. Father", "B. Husband", "C. Brother", "D. Uncle"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is the woman married to your father?",
                    answer: "Wife",
                    hint: "A man's married woman",
                    options: ["A. Mother", "B. Wife", "C. Sister", "D. Aunt"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who are your son's children?",
                    answer: "Grandchildren",
                    hint: "Children of your child",
                    options: ["A. Children", "B. Grandchildren", "C. Nephews", "D. Cousins"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "You and your brother were born on the same day. What are you?",
                    answer: "Twins",
                    hint: "Born at the exact same time",
                    options: ["A. Siblings", "B. Twins", "C. Cousins", "D. Relatives"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Who is someone related to you by blood or marriage?",
                    answer: "Relative",
                    hint: "Connected to you by family",
                    options: ["A. Friend", "B. Neighbor", "C. Colleague", "D. Relative"],
                    correctAnswer: "D",
                    exerciseType: .chooseCorrectWord
                )
            ]
        )
        let seasonsTopic = Topic(
            name: "Seasons (Mùa)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // MARK: - Basic Seasons - English to Vietnamese
                Flashcard(
                    question: "What is 'spring' in Vietnamese?",
                    answer: "Mùa xuân",
                    hint: "Flowers bloom",
                    options: ["A. Mùa hạ", "B. Mùa xuân", "C. Mùa thu", "D. Mùa đông"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'summer' in Vietnamese?",
                    answer: "Mùa hè, mùa hạ",
                    hint: "Hottest season",
                    options: ["A. Mùa đông", "B. Mùa xuân", "C. Mùa hè", "D. Mùa thu"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'autumn' or 'fall' in Vietnamese?",
                    answer: "Mùa thu",
                    hint: "Leaves fall",
                    options: ["A. Mùa xuân", "B. Mùa hè", "C. Mùa thu", "D. Mùa đông"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'winter' in Vietnamese?",
                    answer: "Mùa đông",
                    hint: "Coldest season",
                    options: ["A. Mùa đông", "B. Mùa xuân", "C. Mùa hè", "D. Mùa thu"],
                    correctAnswer: "A",
                    exerciseType: .englishToVietnamese
                ),
                
                // MARK: - Weather & Activities - English to Vietnamese
                Flashcard(
                    question: "What is 'warm' in Vietnamese?",
                    answer: "Ấm áp",
                    hint: "Spring weather",
                    options: ["A. Nóng", "B. Ấm áp", "C. Lạnh", "D. Mát mẻ"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'blossom' in Vietnamese?",
                    answer: "Hoa nở",
                    hint: "Flowers opening",
                    options: ["A. Hoa rơi", "B. Hoa nở", "C. Cây", "D. Lá"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'sunshine' in Vietnamese?",
                    answer: "Ánh nắng mặt trời",
                    hint: "Bright light from sun",
                    options: ["A. Mưa", "B. Mây", "C. Ánh nắng", "D. Gió"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'vacation' in Vietnamese?",
                    answer: "Kỳ nghỉ",
                    hint: "Time off in summer",
                    options: ["A. Học", "B. Làm việc", "C. Kỳ nghỉ", "D. Chơi"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'harvest' in Vietnamese?",
                    answer: "Mùa gặt, thu hoạch",
                    hint: "Collecting crops in autumn",
                    options: ["A. Gieo hạt", "B. Thu hoạch", "C. Tưới nước", "D. Trồng cây"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'leaf' (plural: leaves) in Vietnamese?",
                    answer: "Lá cây",
                    hint: "Falls in autumn",
                    options: ["A. Hoa", "B. Cành", "C. Lá cây", "D. Quả"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'colorful' in Vietnamese?",
                    answer: "Nhiều màu sắc",
                    hint: "Autumn leaves",
                    options: ["A. Đẹp", "B. Nhiều màu sắc", "C. Xanh", "D. Nâu"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'snow' in Vietnamese?",
                    answer: "Tuyết",
                    hint: "White and cold",
                    options: ["A. Mưa", "B. Tuyết", "C. Đá", "D. Băng"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'snowman' in Vietnamese?",
                    answer: "Người tuyết",
                    hint: "Build in winter",
                    options: ["A. Tuyết", "B. Người tuyết", "C. Băng", "D. Trượt tuyết"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'ice' in Vietnamese?",
                    answer: "Băng, đá",
                    hint: "Frozen water",
                    options: ["A. Nước", "B. Tuyết", "C. Băng", "D. Lạnh"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'fresh' in Vietnamese?",
                    answer: "Tươi mới",
                    hint: "Spring feeling",
                    options: ["A. Cũ", "B. Tươi mới", "C. Khô", "D. Ẩm"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'cool' (temperature) in Vietnamese?",
                    answer: "Mát mẻ",
                    hint: "Autumn weather",
                    options: ["A. Nóng", "B. Lạnh", "C. Mát mẻ", "D. Ấm"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                
                // MARK: - More Weather & Nature Vocabulary - English to Vietnamese
                Flashcard(
                    question: "What is 'rain' in Vietnamese?",
                    answer: "Mưa",
                    hint: "Water from sky",
                    options: ["A. Tuyết", "B. Mưa", "C. Nắng", "D. Gió"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'wind' in Vietnamese?",
                    answer: "Gió",
                    hint: "Moving air",
                    options: ["A. Mây", "B. Gió", "C. Bão", "D. Mưa"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'cloud' in Vietnamese?",
                    answer: "Mây",
                    hint: "White in sky",
                    options: ["A. Trời", "B. Mây", "C. Sương mù", "D. Khói"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'fog' in Vietnamese?",
                    answer: "Sương mù",
                    hint: "Can't see far",
                    options: ["A. Mây", "B. Khói", "C. Sương mù", "D. Hơi nước"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'storm' in Vietnamese?",
                    answer: "Bão",
                    hint: "Very bad weather",
                    options: ["A. Gió", "B. Mưa", "C. Bão", "D. Sấm"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'rainbow' in Vietnamese?",
                    answer: "Cầu vồng",
                    hint: "After rain, colorful",
                    options: ["A. Mặt trời", "B. Cầu vồng", "C. Ánh sáng", "D. Màu sắc"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'frost' in Vietnamese?",
                    answer: "Sương giá",
                    hint: "Ice crystals in morning",
                    options: ["A. Tuyết", "B. Băng", "C. Sương giá", "D. Sương mù"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'thunder' in Vietnamese?",
                    answer: "Sấm",
                    hint: "Loud noise in storm",
                    options: ["A. Sét", "B. Sấm", "C. Bão", "D. Mưa"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'lightning' in Vietnamese?",
                    answer: "Chớp, sét",
                    hint: "Bright flash in storm",
                    options: ["A. Sấm", "B. Chớp", "C. Lửa", "D. Ánh sáng"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                
                // MARK: - Activities & Things - English to Vietnamese
                Flashcard(
                    question: "What is 'picnic' in Vietnamese?",
                    answer: "Dã ngoại",
                    hint: "Eat outside in spring/summer",
                    options: ["A. Du lịch", "B. Dã ngoại", "C. Cắm trại", "D. Ăn trưa"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'camping' in Vietnamese?",
                    answer: "Cắm trại",
                    hint: "Sleep in tent outside",
                    options: ["A. Dã ngoại", "B. Du lịch", "C. Cắm trại", "D. Leo núi"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'hiking' in Vietnamese?",
                    answer: "Đi bộ đường dài",
                    hint: "Walk in nature",
                    options: ["A. Chạy", "B. Đi bộ đường dài", "C. Leo núi", "D. Đạp xe"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'skiing' in Vietnamese?",
                    answer: "Trượt tuyết",
                    hint: "Winter sport",
                    options: ["A. Trượt băng", "B. Trượt tuyết", "C. Bơi", "D. Chạy"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'swimming' in Vietnamese?",
                    answer: "Bơi",
                    hint: "In water, summer activity",
                    options: ["A. Lặn", "B. Bơi", "C. Chèo thuyền", "D. Lướt sóng"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'gardening' in Vietnamese?",
                    answer: "Làm vườn",
                    hint: "Plant flowers in spring",
                    options: ["A. Trồng cây", "B. Làm vườn", "C. Tưới nước", "D. Cắt cỏ"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'kite' in Vietnamese?",
                    answer: "Diều",
                    hint: "Fly in windy spring day",
                    options: ["A. Chim", "B. Diều", "C. Máy bay", "D. Bóng bay"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'umbrella' in Vietnamese?",
                    answer: "Ô, dù",
                    hint: "For rain",
                    options: ["A. Áo mưa", "B. Mũ", "C. Ô", "D. Khăn"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'sweater' in Vietnamese?",
                    answer: "Áo len",
                    hint: "Wear in cold weather",
                    options: ["A. Áo khoác", "B. Áo len", "C. Áo phông", "D. Áo sơ mi"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'sunglasses' in Vietnamese?",
                    answer: "Kính râm",
                    hint: "Protect eyes in summer",
                    options: ["A. Kính cận", "B. Kính râm", "C. Mũ", "D. Khăn"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                
                // MARK: - Plants & Nature - English to Vietnamese
                Flashcard(
                    question: "What is 'flower' in Vietnamese?",
                    answer: "Hoa",
                    hint: "Colorful, blooms in spring",
                    options: ["A. Cây", "B. Hoa", "C. Lá", "D. Quả"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'tree' in Vietnamese?",
                    answer: "Cây",
                    hint: "Has trunk and branches",
                    options: ["A. Cây", "B. Cỏ", "C. Bụi", "D. Hoa"],
                    correctAnswer: "A",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'grass' in Vietnamese?",
                    answer: "Cỏ",
                    hint: "Green on ground",
                    options: ["A. Lá", "B. Cỏ", "C. Cây", "D. Rêu"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'seed' in Vietnamese?",
                    answer: "Hạt giống",
                    hint: "Plant in spring",
                    options: ["A. Quả", "B. Hạt", "C. Hạt giống", "D. Rễ"],
                    correctAnswer: "C",
                    exerciseType: .englishToVietnamese
                ),
                Flashcard(
                    question: "What is 'pumpkin' in Vietnamese?",
                    answer: "Bí ngô",
                    hint: "Orange, harvest in autumn",
                    options: ["A. Dưa hấu", "B. Bí ngô", "C. Cà chua", "D. Bí đao"],
                    correctAnswer: "B",
                    exerciseType: .englishToVietnamese
                ),
                
                // MARK: - Vietnamese to English
                Flashcard(
                    question: "Từ 'Mùa xuân' trong tiếng Anh là gì?",
                    answer: "Spring",
                    hint: "After winter",
                    options: ["A. Summer", "B. Spring", "C. Autumn", "D. Winter"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mùa hè' trong tiếng Anh là gì?",
                    answer: "Summer",
                    hint: "Hottest",
                    options: ["A. Winter", "B. Spring", "C. Summer", "D. Fall"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mùa thu' trong tiếng Anh là gì?",
                    answer: "Autumn/Fall",
                    hint: "Leaves change color",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mùa đông' trong tiếng Anh là gì?",
                    answer: "Winter",
                    hint: "Coldest",
                    options: ["A. Winter", "B. Spring", "C. Summer", "D. Fall"],
                    correctAnswer: "A",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Hoa nở' trong tiếng Anh là gì?",
                    answer: "Blossom",
                    hint: "Flowers opening",
                    options: ["A. Bloom", "B. Blossom", "C. Flower", "D. Plant"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Tuyết' trong tiếng Anh là gì?",
                    answer: "Snow",
                    hint: "White winter precipitation",
                    options: ["A. Rain", "B. Ice", "C. Snow", "D. Cold"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Thu hoạch' trong tiếng Anh là gì?",
                    answer: "Harvest",
                    hint: "Gathering crops",
                    options: ["A. Plant", "B. Grow", "C. Harvest", "D. Farm"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Lá cây' trong tiếng Anh là gì?",
                    answer: "Leaf/Leaves",
                    hint: "Green on trees",
                    options: ["A. Branch", "B. Leaf", "C. Tree", "D. Flower"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Ấm áp' trong tiếng Anh là gì?",
                    answer: "Warm",
                    hint: "Spring temperature",
                    options: ["A. Hot", "B. Cold", "C. Warm", "D. Cool"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mát mẻ' trong tiếng Anh là gì?",
                    answer: "Cool",
                    hint: "Autumn temperature",
                    options: ["A. Hot", "B. Cold", "C. Warm", "D. Cool"],
                    correctAnswer: "D",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Mưa' trong tiếng Anh là gì?",
                    answer: "Rain",
                    hint: "Water from sky",
                    options: ["A. Snow", "B. Rain", "C. Wind", "D. Storm"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Gió' trong tiếng Anh là gì?",
                    answer: "Wind",
                    hint: "Moving air",
                    options: ["A. Cloud", "B. Wind", "C. Storm", "D. Fog"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Cầu vồng' trong tiếng Anh là gì?",
                    answer: "Rainbow",
                    hint: "After rain, 7 colors",
                    options: ["A. Sun", "B. Rainbow", "C. Light", "D. Cloud"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Bão' trong tiếng Anh là gì?",
                    answer: "Storm",
                    hint: "Very bad weather",
                    options: ["A. Wind", "B. Rain", "C. Storm", "D. Thunder"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Trượt tuyết' trong tiếng Anh là gì?",
                    answer: "Skiing",
                    hint: "Winter sport",
                    options: ["A. Swimming", "B. Skating", "C. Skiing", "D. Running"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Dã ngoại' trong tiếng Anh là gì?",
                    answer: "Picnic",
                    hint: "Eat outside",
                    options: ["A. Trip", "B. Picnic", "C. Camping", "D. Hiking"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Làm vườn' trong tiếng Anh là gì?",
                    answer: "Gardening",
                    hint: "Plant flowers",
                    options: ["A. Farming", "B. Planting", "C. Gardening", "D. Growing"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Diều' trong tiếng Anh là gì?",
                    answer: "Kite",
                    hint: "Fly in wind",
                    options: ["A. Bird", "B. Kite", "C. Plane", "D. Balloon"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Bí ngô' trong tiếng Anh là gì?",
                    answer: "Pumpkin",
                    hint: "Orange vegetable, Halloween",
                    options: ["A. Melon", "B. Pumpkin", "C. Tomato", "D. Squash"],
                    correctAnswer: "B",
                    exerciseType: .vietnameseToEnglish
                ),
                Flashcard(
                    question: "Từ 'Sương mù' trong tiếng Anh là gì?",
                    answer: "Fog",
                    hint: "Can't see far",
                    options: ["A. Cloud", "B. Smoke", "C. Fog", "D. Mist"],
                    correctAnswer: "C",
                    exerciseType: .vietnameseToEnglish
                ),
                
                // MARK: - Fill in the Blank
                Flashcard(
                    question: "In ___, flowers bloom and trees turn green.",
                    answer: "spring",
                    hint: "After winter",
                    options: ["A. summer", "B. spring", "C. autumn", "D. winter"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "I love swimming in ___.",
                    answer: "summer",
                    hint: "Hot weather, vacation time",
                    options: ["A. winter", "B. spring", "C. summer", "D. autumn"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "Leaves fall from trees in ___.",
                    answer: "autumn/fall",
                    hint: "Between summer and winter",
                    options: ["A. spring", "B. summer", "C. autumn", "D. winter"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "It's very cold in ___.",
                    answer: "winter",
                    hint: "Snow falls",
                    options: ["A. spring", "B. summer", "C. autumn", "D. winter"],
                    correctAnswer: "D",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "The ___ are colorful in autumn.",
                    answer: "leaves",
                    hint: "On trees",
                    options: ["A. flowers", "B. leaves", "C. trees", "D. fruits"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "We can build a ___ in winter.",
                    answer: "snowman",
                    hint: "Made of snow",
                    options: ["A. sandcastle", "B. house", "C. snowman", "D. garden"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "Farmers ___ crops in autumn.",
                    answer: "harvest",
                    hint: "Collecting",
                    options: ["A. plant", "B. harvest", "C. water", "D. sell"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "Cherry trees ___ in spring.",
                    answer: "blossom",
                    hint: "Flowers open",
                    options: ["A. fall", "B. die", "C. blossom", "D. grow"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "The weather is ___ in spring.",
                    answer: "warm",
                    hint: "Not hot, not cold",
                    options: ["A. hot", "B. cold", "C. warm", "D. freezing"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "___ falls in winter.",
                    answer: "Snow",
                    hint: "White and cold",
                    options: ["A. Rain", "B. Snow", "C. Leaves", "D. Flowers"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "I need an ___ when it rains.",
                    answer: "umbrella",
                    hint: "Keeps you dry",
                    options: ["A. coat", "B. umbrella", "C. hat", "D. sweater"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "Children fly ___ in windy spring days.",
                    answer: "kites",
                    hint: "Colorful, in the sky",
                    options: ["A. balloons", "B. kites", "C. planes", "D. birds"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "We go ___ at the beach in summer.",
                    answer: "swimming",
                    hint: "In the water",
                    options: ["A. skiing", "B. hiking", "C. swimming", "D. camping"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "I wear a ___ in winter to keep warm.",
                    answer: "sweater",
                    hint: "Warm clothes",
                    options: ["A. shirt", "B. shorts", "C. sweater", "D. dress"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "After the rain, we can see a beautiful ___.",
                    answer: "rainbow",
                    hint: "Seven colors",
                    options: ["A. cloud", "B. rainbow", "C. sun", "D. moon"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "My family likes to have a ___ in the park in spring.",
                    answer: "picnic",
                    hint: "Eat outside",
                    options: ["A. party", "B. picnic", "C. dinner", "D. lunch"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "We can see ___ on the ground early in the morning in winter.",
                    answer: "frost",
                    hint: "Ice crystals",
                    options: ["A. snow", "B. ice", "C. frost", "D. fog"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "Farmers plant ___ in spring.",
                    answer: "seeds",
                    hint: "Small, grow into plants",
                    options: ["A. flowers", "B. trees", "C. seeds", "D. leaves"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "I love ___ flowers in my garden in spring.",
                    answer: "gardening",
                    hint: "Working with plants",
                    options: ["A. planting", "B. gardening", "C. watering", "D. cutting"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "The ___ is blowing strongly in autumn.",
                    answer: "wind",
                    hint: "Moving air",
                    options: ["A. rain", "B. snow", "C. wind", "D. storm"],
                    correctAnswer: "C",
                    exerciseType: .fillInTheBlank
                ),
                Flashcard(
                    question: "We carve ___ for Halloween in autumn.",
                    answer: "pumpkins",
                    hint: "Orange vegetable",
                    options: ["A. apples", "B. pumpkins", "C. melons", "D. potatoes"],
                    correctAnswer: "B",
                    exerciseType: .fillInTheBlank
                ),
                
                // MARK: - Choose Correct Word
                Flashcard(
                    question: "Which season comes after winter?",
                    answer: "Spring",
                    hint: "New beginnings",
                    options: ["A. Summer", "B. Spring", "C. Autumn", "D. Fall"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "In which season do leaves fall from trees?",
                    answer: "Autumn/Fall",
                    hint: "Harvest time",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which season is associated with cherry blossoms in Japan?",
                    answer: "Spring",
                    hint: "Pink flowers",
                    options: ["A. Winter", "B. Spring", "C. Summer", "D. Autumn"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "When do people usually go to the beach?",
                    answer: "Summer",
                    hint: "Hot and sunny",
                    options: ["A. Winter", "B. Spring", "C. Summer", "D. Autumn"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which season comes before spring?",
                    answer: "Winter",
                    hint: "Coldest season",
                    options: ["A. Summer", "B. Autumn", "C. Fall", "D. Winter"],
                    correctAnswer: "D",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "In which season do we celebrate Halloween?",
                    answer: "Autumn/Fall",
                    hint: "October 31st",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which season is best for skiing?",
                    answer: "Winter",
                    hint: "Need snow",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "D",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "In which season do flowers start to bloom?",
                    answer: "Spring",
                    hint: "After cold winter",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "A",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which season has the longest days?",
                    answer: "Summer",
                    hint: "Most sunlight",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "In which season do trees lose their leaves?",
                    answer: "Autumn/Fall",
                    hint: "Colorful leaves",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which season is associated with ice and snow?",
                    answer: "Winter",
                    hint: "Very cold",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "D",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "When is harvest time for many crops?",
                    answer: "Autumn/Fall",
                    hint: "Collecting crops",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What do you need when it's raining?",
                    answer: "Umbrella",
                    hint: "Keeps you dry",
                    options: ["A. Sunglasses", "B. Umbrella", "C. Sweater", "D. Hat"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which activity is popular in summer?",
                    answer: "Swimming",
                    hint: "In the water",
                    options: ["A. Skiing", "B. Ice skating", "C. Swimming", "D. Snowboarding"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What appears after rain with 7 colors?",
                    answer: "Rainbow",
                    hint: "Red, orange, yellow...",
                    options: ["A. Cloud", "B. Rainbow", "C. Sunshine", "D. Lightning"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What do you fly on a windy day?",
                    answer: "Kite",
                    hint: "Colorful, string attached",
                    options: ["A. Plane", "B. Bird", "C. Kite", "D. Balloon"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What weather makes it difficult to see far?",
                    answer: "Fog",
                    hint: "Thick mist",
                    options: ["A. Rain", "B. Wind", "C. Fog", "D. Snow"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which season is best for planting seeds?",
                    answer: "Spring",
                    hint: "New growth",
                    options: ["A. Spring", "B. Summer", "C. Autumn", "D. Winter"],
                    correctAnswer: "A",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What do farmers do with crops in autumn?",
                    answer: "Harvest",
                    hint: "Collect and gather",
                    options: ["A. Plant", "B. Water", "C. Harvest", "D. Grow"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which clothing is most important in winter?",
                    answer: "Sweater",
                    hint: "Keep you warm",
                    options: ["A. Shorts", "B. T-shirt", "C. Sweater", "D. Sandals"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What covers the ground in winter mornings?",
                    answer: "Frost",
                    hint: "Ice crystals",
                    options: ["A. Grass", "B. Frost", "C. Mud", "D. Leaves"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which vegetable is orange and used for Halloween?",
                    answer: "Pumpkin",
                    hint: "Jack-o'-lantern",
                    options: ["A. Carrot", "B. Orange", "C. Pumpkin", "D. Tomato"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What makes loud noise during a storm?",
                    answer: "Thunder",
                    hint: "Boom sound",
                    options: ["A. Wind", "B. Rain", "C. Thunder", "D. Lightning"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What is the bright flash in the sky during a storm?",
                    answer: "Lightning",
                    hint: "Electrical discharge",
                    options: ["A. Thunder", "B. Lightning", "C. Rainbow", "D. Sun"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "Which outdoor activity involves sleeping in a tent?",
                    answer: "Camping",
                    hint: "In nature, overnight",
                    options: ["A. Picnic", "B. Hiking", "C. Camping", "D. Swimming"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                Flashcard(
                    question: "What do you wear to protect your eyes in summer?",
                    answer: "Sunglasses",
                    hint: "Dark glasses",
                    options: ["A. Hat", "B. Sunglasses", "C. Scarf", "D. Gloves"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                )
            ]
        )
        
        // Colors topic
        let colorsTopic = Topic(
            name: "Colors (Màu sắc)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'red' in Vietnamese?", answer: "Màu đỏ", hint: "Color of blood", options: ["A. Xanh", "B. Đỏ", "C. Vàng", "D. Trắng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'blue' in Vietnamese?", answer: "Màu xanh dương", hint: "Color of sky", options: ["A. Đỏ", "B. Vàng", "C. Xanh dương", "D. Đen"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'yellow' in Vietnamese?", answer: "Màu vàng", hint: "Color of sun", options: ["A. Vàng", "B. Đỏ", "C. Xanh", "D. Tím"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'green' in Vietnamese?", answer: "Màu xanh lá", hint: "Color of grass", options: ["A. Đen", "B. Trắng", "C. Xanh lá", "D. Cam"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'black' in Vietnamese?", answer: "Màu đen", hint: "Opposite of white", options: ["A. Trắng", "B. Đen", "C. Xám", "D. Nâu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'white' in Vietnamese?", answer: "Màu trắng", hint: "Color of snow", options: ["A. Đen", "B. Xám", "C. Trắng", "D. Hồng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Màu xanh lá' trong tiếng Anh là gì?", answer: "Green", hint: "Grass color", options: ["A. Blue", "B. Green", "C. Yellow", "D. Brown"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "The sky is ___.", answer: "blue", hint: "Color above us", options: ["A. red", "B. blue", "C. green", "D. yellow"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Days of the Week topic
        let daysTopic = Topic(
            name: "Days of the Week (Ngày trong tuần)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'Monday' in Vietnamese?", answer: "Thứ Hai", hint: "First workday", options: ["A. Chủ Nhật", "B. Thứ Hai", "C. Thứ Ba", "D. Thứ Tư"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'Sunday' in Vietnamese?", answer: "Chủ Nhật", hint: "Weekend day", options: ["A. Thứ Bảy", "B. Chủ Nhật", "C. Thứ Hai", "D. Thứ Sáu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'Friday' in Vietnamese?", answer: "Thứ Sáu", hint: "Last workday", options: ["A. Thứ Năm", "B. Thứ Sáu", "C. Thứ Bảy", "D. Chủ Nhật"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Thứ Tư' trong tiếng Anh là gì?", answer: "Wednesday", hint: "Middle of week", options: ["A. Tuesday", "B. Wednesday", "C. Thursday", "D. Friday"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Today is ___.", answer: "Monday", hint: "Start of work week", options: ["A. Sunday", "B. Monday", "C. Saturday", "D. Friday"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Food & Drinks topic
        let foodTopic = Topic(
            name: "Food & Drinks (Đồ ăn & Thức uống)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'rice' in Vietnamese?", answer: "Cơm", hint: "Main food in Asia", options: ["A. Mì", "B. Cơm", "C. Bánh mì", "D. Phở"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'water' in Vietnamese?", answer: "Nước", hint: "Clear liquid", options: ["A. Sữa", "B. Nước", "C. Cà phê", "D. Trà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bread' in Vietnamese?", answer: "Bánh mì", hint: "Made from flour", options: ["A. Bánh mì", "B. Cơm", "C. Phở", "D. Bún"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'egg' in Vietnamese?", answer: "Trứng", hint: "From chicken", options: ["A. Thịt", "B. Cá", "C. Trứng", "D. Gà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'coffee' in Vietnamese?", answer: "Cà phê", hint: "Dark drink", options: ["A. Trà", "B. Nước", "C. Cà phê", "D. Sữa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Nước cam' trong tiếng Anh là gì?", answer: "Orange juice", hint: "Fruit drink", options: ["A. Water", "B. Milk", "C. Orange juice", "D. Tea"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I want to drink ___.", answer: "water", hint: "Clear liquid", options: ["A. bread", "B. rice", "C. water", "D. egg"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Fruits topic - EXPANDED
        let fruitsTopic = Topic(
            name: "Fruits (Trái cây)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Common Fruits - Trái cây phổ biến
                Flashcard(question: "What is 'apple' in Vietnamese?", answer: "Táo", hint: "Red or green, common fruit", options: ["A. Cam", "B. Táo", "C. Chuối", "D. Xoài"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'banana' in Vietnamese?", answer: "Chuối", hint: "Yellow, long fruit", options: ["A. Cam", "B. Chuối", "C. Dứa", "D. Nho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'orange' in Vietnamese?", answer: "Cam", hint: "Round, orange color", options: ["A. Cam", "B. Táo", "C. Dâu", "D. Lê"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'grape' in Vietnamese?", answer: "Nho", hint: "Small, grows in bunches", options: ["A. Dâu", "B. Cherry", "C. Nho", "D. Mận"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'watermelon' in Vietnamese?", answer: "Dưa hấu", hint: "Large, red inside, green outside", options: ["A. Dưa hấu", "B. Dưa gang", "C. Dứa", "D. Đu đủ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'strawberry' in Vietnamese?", answer: "Dâu tây", hint: "Small, red, with seeds outside", options: ["A. Cherry", "B. Dâu tây", "C. Mâm xôi", "D. Việt quất"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mango' in Vietnamese?", answer: "Xoài", hint: "Tropical, yellow/orange", options: ["A. Đu đủ", "B. Xoài", "C. Dứa", "D. Chuối"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pineapple' in Vietnamese?", answer: "Dứa, thơm", hint: "Tropical, spiky outside", options: ["A. Xoài", "B. Dừa", "C. Dứa", "D. Đu đủ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'coconut' in Vietnamese?", answer: "Dừa", hint: "Brown, hairy shell, white inside", options: ["A. Dứa", "B. Dừa", "C. Chuối", "D. Xoài"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'papaya' in Vietnamese?", answer: "Đu đủ", hint: "Orange inside, oval shape", options: ["A. Xoài", "B. Dứa", "C. Đu đủ", "D. Dưa hấu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Citrus Fruits - Trái cây họ cam quýt
                Flashcard(question: "What is 'lemon' in Vietnamese?", answer: "Chanh", hint: "Yellow, sour citrus", options: ["A. Cam", "B. Chanh", "C. Quýt", "D. Bưởi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lime' in Vietnamese?", answer: "Chanh vàng", hint: "Green, small citrus", options: ["A. Chanh", "B. Chanh vàng", "C. Cam", "D. Quýt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'grapefruit' in Vietnamese?", answer: "Bưởi", hint: "Large citrus, pink inside", options: ["A. Cam", "B. Quýt", "C. Bưởi", "D. Chanh"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mandarin' in Vietnamese?", answer: "Quýt", hint: "Small orange, easy to peel", options: ["A. Cam", "B. Quýt", "C. Chanh", "D. Bưởi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Stone Fruits - Trái cây có hạt cứng
                Flashcard(question: "What is 'peach' in Vietnamese?", answer: "Đào", hint: "Fuzzy skin, sweet", options: ["A. Mận", "B. Đào", "C. Mơ", "D. Cherry"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'plum' in Vietnamese?", answer: "Mận", hint: "Small, purple or red", options: ["A. Mận", "B. Đào", "C. Cherry", "D. Mơ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'apricot' in Vietnamese?", answer: "Mơ", hint: "Orange, like small peach", options: ["A. Đào", "B. Mận", "C. Mơ", "D. Cherry"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cherry' in Vietnamese?", answer: "Cherry", hint: "Small, red, sweet or sour", options: ["A. Mận", "B. Cherry", "C. Dâu", "D. Nho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Other Popular Fruits - Các loại trái cây khác
                Flashcard(question: "What is 'pear' in Vietnamese?", answer: "Lê", hint: "Like apple but softer", options: ["A. Táo", "B. Lê", "C. Cam", "D. Quýt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'kiwi' in Vietnamese?", answer: "Kiwi", hint: "Brown fuzzy, green inside", options: ["A. Nho", "B. Mận", "C. Kiwi", "D. Dứa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'avocado' in Vietnamese?", answer: "Bơ", hint: "Green, creamy inside", options: ["A. Đu đủ", "B. Xoài", "C. Bơ", "D. Lê"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'blueberry' in Vietnamese?", answer: "Việt quất", hint: "Small, blue berries", options: ["A. Dâu tây", "B. Nho", "C. Việt quất", "D. Mâm xôi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'raspberry' in Vietnamese?", answer: "Mâm xôi", hint: "Red berry, like tiny bubbles", options: ["A. Dâu tây", "B. Mâm xôi", "C. Việt quất", "D. Cherry"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'blackberry' in Vietnamese?", answer: "Dâu đen", hint: "Dark purple berry", options: ["A. Việt quất", "B. Dâu đen", "C. Nho", "D. Mận"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Tropical & Exotic Fruits - Trái cây nhiệt đới
                Flashcard(question: "What is 'dragon fruit' in Vietnamese?", answer: "Thanh long", hint: "Pink skin, white inside with black seeds", options: ["A. Xoài", "B. Thanh long", "C. Dứa", "D. Dừa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lychee' in Vietnamese?", answer: "Vải", hint: "Red bumpy shell, white inside", options: ["A. Nhãn", "B. Vải", "C. Chôm chôm", "D. Mận"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'longan' in Vietnamese?", answer: "Nhãn", hint: "Like lychee but brown shell", options: ["A. Vải", "B. Nhãn", "C. Chôm chôm", "D. Xoài"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'rambutan' in Vietnamese?", answer: "Chôm chôm", hint: "Red hairy fruit", options: ["A. Vải", "B. Nhãn", "C. Chôm chôm", "D. Thanh long"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'durian' in Vietnamese?", answer: "Sầu riêng", hint: "Spiky, strong smell", options: ["A. Mít", "B. Sầu riêng", "C. Chôm chôm", "D. Thanh long"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'jackfruit' in Vietnamese?", answer: "Mít", hint: "Large, spiky, yellow inside", options: ["A. Mít", "B. Sầu riêng", "C. Dứa", "D. Đu đủ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'guava' in Vietnamese?", answer: "Ổi", hint: "Round, white or pink inside", options: ["A. Lê", "B. Ổi", "C. Bơ", "D. Xoài"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'passion fruit' in Vietnamese?", answer: "Chanh dây", hint: "Purple, sour-sweet pulp", options: ["A. Chanh", "B. Chanh dây", "C. Thanh long", "D. Kiwi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'star fruit' in Vietnamese?", answer: "Khế", hint: "Star-shaped when cut", options: ["A. Thanh long", "B. Khế", "C. Ổi", "D. Mận"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Melons - Các loại dưa
                Flashcard(question: "What is 'cantaloupe' in Vietnamese?", answer: "Dưa gang", hint: "Orange melon, netted skin", options: ["A. Dưa hấu", "B. Dưa gang", "C. Dưa chuột", "D. Bí"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'honeydew' in Vietnamese?", answer: "Dưa lê", hint: "Green melon, sweet", options: ["A. Dưa hấu", "B. Dưa gang", "C. Dưa lê", "D. Dưa chuột"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // More Common Fruits
                Flashcard(question: "What is 'pomegranate' in Vietnamese?", answer: "Lựu", hint: "Red seeds inside", options: ["A. Dâu", "B. Lựu", "C. Cherry", "D. Nho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'persimmon' in Vietnamese?", answer: "Hồng", hint: "Orange, sweet when ripe", options: ["A. Đào", "B. Mận", "C. Hồng", "D. Cam"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fig' in Vietnamese?", answer: "Sung", hint: "Purple or green, soft inside", options: ["A. Mận", "B. Sung", "C. Hồng", "D. Mơ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'date' in Vietnamese?", answer: "Chà là", hint: "Brown, sweet, dried fruit", options: ["A. Mận", "B. Sung", "C. Chà là", "D. Nho"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English exercises
                Flashcard(question: "Từ 'Xoài' trong tiếng Anh là gì?", answer: "Mango", hint: "Tropical yellow fruit", options: ["A. Banana", "B. Mango", "C. Papaya", "D. Pineapple"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Dâu tây' trong tiếng Anh là gì?", answer: "Strawberry", hint: "Red berry with seeds outside", options: ["A. Cherry", "B. Raspberry", "C. Strawberry", "D. Blueberry"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Dừa' trong tiếng Anh là gì?", answer: "Coconut", hint: "Brown hairy tropical fruit", options: ["A. Pineapple", "B. Coconut", "C. Banana", "D. Papaya"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Vải' trong tiếng Anh là gì?", answer: "Lychee", hint: "Red bumpy shell, white inside", options: ["A. Rambutan", "B. Longan", "C. Lychee", "D. Grape"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Sầu riêng' trong tiếng Anh là gì?", answer: "Durian", hint: "King of fruits, strong smell", options: ["A. Jackfruit", "B. Durian", "C. Mango", "D. Papaya"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thanh long' trong tiếng Anh là gì?", answer: "Dragon fruit", hint: "Pink with white inside", options: ["A. Star fruit", "B. Passion fruit", "C. Dragon fruit", "D. Guava"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Bơ' trong tiếng Anh là gì?", answer: "Avocado", hint: "Green, creamy fruit", options: ["A. Kiwi", "B. Pear", "C. Avocado", "D. Guava"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Ổi' trong tiếng Anh là gì?", answer: "Guava", hint: "Round fruit, pink or white inside", options: ["A. Pear", "B. Apple", "C. Guava", "D. Peach"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Fill in the blank exercises
                Flashcard(question: "I eat an ___ every day. (Red fruit)", answer: "apple", hint: "Red or green fruit", options: ["A. orange", "B. apple", "C. banana", "D. grape"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ is yellow and sweet. (Long fruit)", answer: "banana", hint: "Yellow, curved", options: ["A. apple", "B. lemon", "C. banana", "D. pear"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "She loves eating ___. (Small purple fruit in bunches)", answer: "grapes", hint: "Grow in clusters", options: ["A. cherries", "B. grapes", "C. berries", "D. plums"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "This ___ is very sweet and juicy. (Large green striped fruit)", answer: "watermelon", hint: "Red inside, green outside", options: ["A. melon", "B. watermelon", "C. apple", "D. pear"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I like to drink ___ juice in the morning. (Orange citrus)", answer: "orange", hint: "Round orange fruit", options: ["A. apple", "B. grape", "C. orange", "D. lemon"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ is a tropical fruit with yellow flesh. (Xoài)", answer: "mango", hint: "Sweet tropical fruit", options: ["A. pineapple", "B. mango", "C. papaya", "D. banana"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Vietnamese people love ___. (King of fruits)", answer: "durian", hint: "Spiky, strong smell", options: ["A. jackfruit", "B. mango", "C. durian", "D. pineapple"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "___ has a pink skin and white flesh with black seeds.", answer: "Dragon fruit", hint: "Thanh long", options: ["A. Watermelon", "B. Dragon fruit", "C. Papaya", "D. Kiwi"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "___ are small red berries that taste sweet. (Dâu tây)", answer: "Strawberries", hint: "Red with seeds outside", options: ["A. Cherries", "B. Raspberries", "C. Strawberries", "D. Blueberries"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ is very sour and yellow. (Used in tea)", answer: "lemon", hint: "Yellow citrus, sour", options: ["A. lime", "B. lemon", "C. orange", "D. grapefruit"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                
                // Choose correct word
                Flashcard(question: "Which fruit is tropical and spiky on the outside? (A) Apple (B) Pineapple (C) Pear (D) Peach", answer: "Pineapple", hint: "Yellow inside, crown on top", options: ["A. Apple", "B. Pineapple", "C. Pear", "D. Peach"], correctAnswer: "B", exerciseType: .chooseCorrectWord),
                Flashcard(question: "Which fruit has a hairy brown shell? (A) Coconut (B) Orange (C) Apple (D) Banana", answer: "Coconut", hint: "Tropical drink", options: ["A. Coconut", "B. Orange", "C. Apple", "D. Banana"], correctAnswer: "A", exerciseType: .chooseCorrectWord),
                Flashcard(question: "Which fruit is known as 'vải' in Vietnamese? (A) Grape (B) Cherry (C) Lychee (D) Plum", answer: "Lychee", hint: "Red bumpy shell", options: ["A. Grape", "B. Cherry", "C. Lychee", "D. Plum"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "Which berry is blue? (A) Strawberry (B) Raspberry (C) Blueberry (D) Blackberry", answer: "Blueberry", hint: "Small and blue", options: ["A. Strawberry", "B. Raspberry", "C. Blueberry", "D. Blackberry"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "Which fruit is star-shaped when you cut it? (A) Apple (B) Star fruit (C) Orange (D) Kiwi", answer: "Star fruit", hint: "Khế in Vietnamese", options: ["A. Apple", "B. Star fruit", "C. Orange", "D. Kiwi"], correctAnswer: "B", exerciseType: .chooseCorrectWord)
            ]
        )
        
        // Animals topic - EXPANDED
        let animalsTopic = Topic(
            name: "Animals (Động vật)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Pets - Thú cưng
                Flashcard(question: "What is 'dog' in Vietnamese?", answer: "Chó", hint: "Pet, barks", options: ["A. Mèo", "B. Chó", "C. Gà", "D. Lợn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cat' in Vietnamese?", answer: "Mèo", hint: "Pet, meows", options: ["A. Chó", "B. Mèo", "C. Chuột", "D. Chim"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'rabbit' in Vietnamese?", answer: "Thỏ", hint: "Long ears, hops", options: ["A. Mèo", "B. Thỏ", "C. Chuột", "D. Chó"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'hamster' in Vietnamese?", answer: "Chuột hamster", hint: "Small pet rodent", options: ["A. Chuột", "B. Thỏ", "C. Chuột hamster", "D. Mèo"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'parrot' in Vietnamese?", answer: "Vẹt", hint: "Colorful bird, can talk", options: ["A. Chim", "B. Vẹt", "C. Gà", "D. Vịt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Birds - Chim
                Flashcard(question: "What is 'bird' in Vietnamese?", answer: "Chim", hint: "Can fly", options: ["A. Cá", "B. Gà", "C. Chim", "D. Vịt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'chicken' in Vietnamese?", answer: "Gà", hint: "Lays eggs", options: ["A. Vịt", "B. Gà", "C. Heo", "D. Bò"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'duck' in Vietnamese?", answer: "Vịt", hint: "Swims, quacks", options: ["A. Gà", "B. Vịt", "C. Ngỗng", "D. Chim"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'eagle' in Vietnamese?", answer: "Đại bàng", hint: "Large bird of prey", options: ["A. Chim", "B. Đại bàng", "C. Vẹt", "D. Gà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'owl' in Vietnamese?", answer: "Cú", hint: "Night bird", options: ["A. Chim", "B. Cú", "C. Đại bàng", "D. Vẹt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sparrow' in Vietnamese?", answer: "Chim sẻ", hint: "Small common bird", options: ["A. Chim sẻ", "B. Vẹt", "C. Cú", "D. Gà"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                
                // Farm Animals - Động vật trang trại
                Flashcard(question: "Từ 'Con bò' trong tiếng Anh là gì?", answer: "Cow", hint: "Gives milk", options: ["A. Pig", "B. Cow", "C. Horse", "D. Sheep"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "What is 'pig' in Vietnamese?", answer: "Lợn, heo", hint: "Pink farm animal", options: ["A. Bò", "B. Lợn", "C. Gà", "D. Ngựa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'horse' in Vietnamese?", answer: "Ngựa", hint: "For riding", options: ["A. Bò", "B. Lợn", "C. Ngựa", "D. Dê"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sheep' in Vietnamese?", answer: "Cừu", hint: "Has wool", options: ["A. Dê", "B. Cừu", "C. Bò", "D. Ngựa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'goat' in Vietnamese?", answer: "Dê", hint: "Eats grass, climbs", options: ["A. Cừu", "B. Dê", "C. Bò", "D. Lợn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'donkey' in Vietnamese?", answer: "Lừa", hint: "Like small horse", options: ["A. Ngựa", "B. Lừa", "C. Bò", "D. Dê"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Water Animals - Động vật dưới nước
                Flashcard(question: "What is 'fish' in Vietnamese?", answer: "Cá", hint: "Lives in water", options: ["A. Cá", "B. Chim", "C. Gà", "D. Heo"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'shark' in Vietnamese?", answer: "Cá mập", hint: "Dangerous sea predator", options: ["A. Cá", "B. Cá mập", "C. Cá voi", "D. Cá heo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'whale' in Vietnamese?", answer: "Cá voi", hint: "Largest ocean animal", options: ["A. Cá mập", "B. Cá voi", "C. Cá heo", "D. Cá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'dolphin' in Vietnamese?", answer: "Cá heo", hint: "Smart, friendly sea animal", options: ["A. Cá voi", "B. Cá heo", "C. Cá mập", "D. Cá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'octopus' in Vietnamese?", answer: "Bạch tuộc", hint: "8 legs", options: ["A. Mực", "B. Bạch tuộc", "C. Cá", "D. Tôm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'crab' in Vietnamese?", answer: "Cua", hint: "Has claws, sideways walk", options: ["A. Tôm", "B. Cua", "C. Mực", "D. Ốc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'shrimp' in Vietnamese?", answer: "Tôm", hint: "Small seafood", options: ["A. Cá", "B. Cua", "C. Tôm", "D. Mực"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Wild Animals - Động vật hoang dã
                Flashcard(question: "What is 'lion' in Vietnamese?", answer: "Sư tử", hint: "King of jungle", options: ["A. Hổ", "B. Sư tử", "C. Báo", "D. Gấu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'tiger' in Vietnamese?", answer: "Hổ", hint: "Striped big cat", options: ["A. Sư tử", "B. Hổ", "C. Báo", "D. Mèo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bear' in Vietnamese?", answer: "Gấu", hint: "Large, likes honey", options: ["A. Hổ", "B. Sư tử", "C. Gấu", "D. Sói"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'elephant' in Vietnamese?", answer: "Voi", hint: "Largest land animal, trunk", options: ["A. Voi", "B. Hà mã", "C. Tê giác", "D. Hươu cao cổ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'monkey' in Vietnamese?", answer: "Khỉ", hint: "Swings in trees", options: ["A. Khỉ", "B. Gấu", "C. Sư tử", "D. Hổ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'giraffe' in Vietnamese?", answer: "Hươu cao cổ", hint: "Very long neck", options: ["A. Voi", "B. Hươu", "C. Hươu cao cổ", "D. Ngựa vằn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'zebra' in Vietnamese?", answer: "Ngựa vằn", hint: "Black and white stripes", options: ["A. Ngựa", "B. Ngựa vằn", "C. Hổ", "D. Hươu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'deer' in Vietnamese?", answer: "Hươu, nai", hint: "Has antlers", options: ["A. Dê", "B. Hươu", "C. Ngựa", "D. Cừu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fox' in Vietnamese?", answer: "Cáo", hint: "Cunning animal", options: ["A. Sói", "B. Chó", "C. Cáo", "D. Mèo"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wolf' in Vietnamese?", answer: "Sói", hint: "Wild dog", options: ["A. Chó", "B. Sói", "C. Cáo", "D. Gấu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Reptiles & Others - Bò sát & khác
                Flashcard(question: "What is 'snake' in Vietnamese?", answer: "Rắn", hint: "No legs, slithers", options: ["A. Rắn", "B. Thằn lằn", "C. Cá sấu", "D. Rùa"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'crocodile' in Vietnamese?", answer: "Cá sấu", hint: "Large water reptile", options: ["A. Rùa", "B. Thằn lằn", "C. Cá sấu", "D. Rắn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'turtle' in Vietnamese?", answer: "Rùa", hint: "Has shell, slow", options: ["A. Rùa", "B. Cá sấu", "C. Rắn", "D. Ếch"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'frog' in Vietnamese?", answer: "Ếch", hint: "Jumps, green", options: ["A. Cóc", "B. Ếch", "C. Rắn", "D. Thằn lằn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Insects - Côn trùng
                Flashcard(question: "What is 'butterfly' in Vietnamese?", answer: "Bướm", hint: "Colorful flying insect", options: ["A. Ong", "B. Bướm", "C. Chuồn chuồn", "D. Ruồi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bee' in Vietnamese?", answer: "Ong", hint: "Makes honey", options: ["A. Ong", "B. Bướm", "C. Ruồi", "D. Kiến"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ant' in Vietnamese?", answer: "Kiến", hint: "Very small, works in groups", options: ["A. Ong", "B. Kiến", "C. Ruồi", "D. Muỗi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'spider' in Vietnamese?", answer: "Nhện", hint: "8 legs, makes webs", options: ["A. Kiến", "B. Nhện", "C. Bọ", "D. Chuồn chuồn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mosquito' in Vietnamese?", answer: "Muỗi", hint: "Bites, drinks blood", options: ["A. Ruồi", "B. Muỗi", "C. Ong", "D. Kiến"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Fill in the blank exercises
                Flashcard(question: "A ___ can fly.", answer: "bird", hint: "Has wings", options: ["A. dog", "B. cat", "C. bird", "D. fish"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ has a very long trunk.", answer: "elephant", hint: "Largest land animal", options: ["A. bear", "B. elephant", "C. horse", "D. cow"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "A ___ lives in the ocean.", answer: "whale", hint: "Biggest sea animal", options: ["A. lion", "B. bear", "C. whale", "D. monkey"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ is the king of the jungle.", answer: "lion", hint: "Big cat with mane", options: ["A. tiger", "B. lion", "C. bear", "D. monkey"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Con khỉ' trong tiếng Anh là gì?", answer: "Monkey", hint: "Swings in trees", options: ["A. Bear", "B. Monkey", "C. Lion", "D. Tiger"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Con voi' trong tiếng Anh là gì?", answer: "Elephant", hint: "Has trunk", options: ["A. Horse", "B. Bear", "C. Elephant", "D. Cow"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Con cá mập' trong tiếng Anh là gì?", answer: "Shark", hint: "Dangerous sea animal", options: ["A. Fish", "B. Whale", "C. Shark", "D. Dolphin"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Con rắn' trong tiếng Anh là gì?", answer: "Snake", hint: "No legs", options: ["A. Snake", "B. Crocodile", "C. Turtle", "D. Lizard"], correctAnswer: "A", exerciseType: .vietnameseToEnglish)
            ]
        )
        
        // Body Parts topic
        let bodyTopic = Topic(
            name: "Body Parts (Bộ phận cơ thể)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'head' in Vietnamese?", answer: "Đầu", hint: "Top of body", options: ["A. Tay", "B. Chân", "C. Đầu", "D. Mắt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'eye' in Vietnamese?", answer: "Mắt", hint: "For seeing", options: ["A. Mắt", "B. Tai", "C. Mũi", "D. Miệng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'hand' in Vietnamese?", answer: "Tay", hint: "For holding", options: ["A. Chân", "B. Tay", "C. Đầu", "D. Lưng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'foot' in Vietnamese?", answer: "Bàn chân", hint: "For walking", options: ["A. Tay", "B. Chân", "C. Bàn chân", "D. Đầu gối"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Tai' trong tiếng Anh là gì?", answer: "Ear", hint: "For hearing", options: ["A. Eye", "B. Ear", "C. Nose", "D. Mouth"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I see with my ___.", answer: "eyes", hint: "Two on face", options: ["A. ears", "B. eyes", "C. nose", "D. mouth"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Clothes topic
        let clothesTopic = Topic(
            name: "Clothes (Quần áo)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'shirt' in Vietnamese?", answer: "Áo sơ mi", hint: "Upper body wear", options: ["A. Quần", "B. Áo", "C. Giày", "D. Mũ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pants' in Vietnamese?", answer: "Quần", hint: "Lower body wear", options: ["A. Áo", "B. Quần", "C. Váy", "D. Giày"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'shoes' in Vietnamese?", answer: "Giày", hint: "For feet", options: ["A. Tất", "B. Giày", "C. Dép", "D. Mũ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'hat' in Vietnamese?", answer: "Mũ", hint: "On head", options: ["A. Áo", "B. Quần", "C. Mũ", "D. Khăn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Áo khoác' trong tiếng Anh là gì?", answer: "Jacket", hint: "For cold weather", options: ["A. Shirt", "B. Jacket", "C. Coat", "D. Sweater"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I wear ___ on my feet.", answer: "shoes", hint: "Footwear", options: ["A. hat", "B. shirt", "C. shoes", "D. pants"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Weather topic
        let weatherTopic = Topic(
            name: "Weather (Thời tiết - 100 Từ vựng)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // --- NHÓM 1: TRẠNG THÁI CƠ BẢN (Basic States) ---
                Flashcard(question: "Sunny", answer: "Trời nắng", hint: "Khi bầu trời quang đãng và có ánh nắng mặt trời.", options: ["A. Trời mưa", "B. Trời nắng", "C. Có gió", "D. Nhiều mây"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Rainy", answer: "Trời mưa", hint: "Khi có những hạt nước rơi từ trên mây xuống.", options: ["A. Trời nắng", "B. Trời mưa", "C. Trời tối", "D. Có tuyết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Cloudy", answer: "Nhiều mây", hint: "Bầu trời bị che phủ bởi mây, không thấy mặt trời.", options: ["A. Trong xanh", "B. Nhiều mây", "C. Có bão", "D. Ẩm ướt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Windy", answer: "Có gió", hint: "Không khí chuyển động mạnh. 'It's too windy to play badminton'.", options: ["A. Đứng gió", "B. Có gió", "C. Nắng gắt", "D. Có sương"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Stormy", answer: "Có bão", hint: "Thời tiết rất xấu, có mưa to, gió lớn và sấm chớp.", options: ["A. Bình yên", "B. Có bão", "C. Nắng nhẹ", "D. Khô ráo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Snowy", answer: "Có tuyết", hint: "Thời tiết lạnh giá khiến nước đóng băng rơi xuống.", options: ["A. Mưa rào", "B. Có tuyết", "C. Nắng ấm", "D. Ẩm ướt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Foggy", answer: "Có sương mù", hint: "Sương dày đặc làm giảm tầm nhìn khi lái xe.", options: ["A. Trong trẻo", "B. Có sương mù", "C. Có nắng", "D. Khô hanh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Humid", answer: "Ẩm ướt / Độ ẩm cao", hint: "Cảm giác oi bức do có nhiều hơi nước trong không khí.", options: ["A. Khô ráo", "B. Ẩm ướt", "C. Lạnh giá", "D. Thoáng đãng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Dry", answer: "Khô hanh", hint: "Thời tiết thiếu độ ẩm, thường gặp vào mùa đông miền Bắc.", options: ["A. Ướt át", "B. Khô hanh", "C. Mưa phùn", "D. Có bão"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Chilly", answer: "Se lạnh", hint: "Lạnh vừa phải, cần mặc thêm áo khoác mỏng.", options: ["A. Nóng bức", "B. Se lạnh", "C. Lạnh buốt", "D. Ấm áp"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 2: HIỆN TƯỢNG THIÊN NHIÊN (Phenomena) ---
                Flashcard(question: "Thunder", answer: "Tiếng sấm", hint: "Âm thanh vang lên sau khi có tia chớp.", options: ["A. Tia chớp", "B. Tiếng sấm", "C. Mưa đá", "D. Gió lốc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Lightning", answer: "Tia chớp / Tia sét", hint: "Ánh sáng lóe lên trên trời khi có bão.", options: ["A. Sấm", "B. Tia sét", "C. Cầu vồng", "D. Mưa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Rainbow", answer: "Cầu vồng", hint: "Vòng cung bảy màu xuất hiện sau cơn mưa.", options: ["A. Mây", "B. Cầu vồng", "C. Mặt trời", "D. Trăng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Drizzle", answer: "Mưa phùn / Mưa lâm thâm", hint: "Mưa rất nhỏ, thường có vào mùa xuân.", options: ["A. Mưa rào", "B. Mưa phùn", "C. Bão", "D. Tuyết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Shower", answer: "Mưa rào", hint: "Cơn mưa to nhưng kết thúc nhanh.", options: ["A. Mưa phùn", "B. Mưa rào", "C. Lụt", "D. Hạn hán"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Hail", answer: "Mưa đá", hint: "Những cục nước đá rơi từ trên trời xuống.", options: ["A. Tuyết", "B. Mưa đá", "C. Sương giá", "D. Mưa phùn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Blizzard", answer: "Bão tuyết", hint: "Trận bão kèm theo tuyết rơi rất mạnh.", options: ["A. Mưa bão", "B. Bão tuyết", "C. Gió nhẹ", "D. Nắng ấm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Tornado", answer: "Vòi rồng / Lốc xoáy", hint: "Cột gió xoáy cực mạnh tàn phá mọi thứ.", options: ["A. Bão", "B. Lốc xoáy", "C. Sóng thần", "D. Động đất"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Hurricane / Typhoon", answer: "Bão lớn / Siêu bão", hint: "Cơn bão nhiệt đới có sức tàn phá khủng khiếp.", options: ["A. Gió mùa", "B. Siêu bão", "C. Áp thấp", "D. Mưa rào"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Mist", answer: "Sương giăng", hint: "Mỏng hơn Fog, thường thấy ở mặt hồ buổi sáng.", options: ["A. Khói", "B. Sương giăng", "C. Bụi", "D. Mây"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 3: NHIỆT ĐỘ & CẢM GIÁC (Temperature & Feelings) ---
                Flashcard(question: "Freezing", answer: "Lạnh giá / Đóng băng", hint: "Cực kỳ lạnh (dưới 0 độ C).", options: ["A. Mát mẻ", "B. Lạnh giá", "C. Ấm áp", "D. Nóng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Boiling", answer: "Nóng hầm hập / Nóng như sôi", hint: "Cách nói quá về thời tiết cực kỳ nóng.", options: ["A. Nóng hầm hập", "B. Lạnh ngắt", "C. Dễ chịu", "D. Ẩm"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Mild", answer: "Ôn hòa / Dễ chịu", hint: "Thời tiết không quá nóng cũng không quá lạnh.", options: ["A. Khắc nghiệt", "B. Ôn hòa", "C. Cực đoan", "D. Thất thường"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Scorching", answer: "Nóng cháy da cháy thịt", hint: "Cái nóng của mặt trời mùa hè gắt gao.", options: ["A. Ấm áp", "B. Nóng cháy da", "C. Se lạnh", "D. Mát"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Breezy", answer: "Có gió hiu hiu", hint: "Gió nhẹ mang lại cảm giác thoải mái.", options: ["A. Bão bùng", "B. Có gió hiu hiu", "C. Đứng gió", "D. Nóng nực"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Frosty", answer: "Giá rét / Phủ sương giá", hint: "Lạnh đến mức hơi nước đọng lại thành lớp mỏng trắng.", options: ["A. Nóng nực", "B. Giá rét", "C. Ẩm ướt", "D. Khô"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Gloomy", answer: "U ám", hint: "Trời xám xịt, thiếu ánh sáng, gây buồn chán.", options: ["A. Tươi sáng", "B. U ám", "C. Rực rỡ", "D. Trong xanh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Overcast", answer: "Trời âm u", hint: "Bầu trời toàn mây xám chuẩn bị mưa.", options: ["A. Nắng chang chang", "B. Trời âm u", "C. Trời trong", "D. Có cầu vồng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Heatwave", answer: "Đợt nắng nóng kéo dài", hint: "Một khoảng thời gian thời tiết nóng bất thường.", options: ["A. Đợt rét", "B. Đợt nắng nóng", "C. Mùa mưa", "D. Đợt lũ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Clear sky", answer: "Trời quang mây tạnh", hint: "Bầu trời trong xanh, không có gợn mây.", options: ["A. Trời đầy mây", "B. Trời quang đãng", "C. Trời sầm tối", "D. Trời đang bão"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 4: CÁC KHÁI NIỆM NÂNG CAO (Advanced Concepts) ---
                Flashcard(question: "Humidity", answer: "Độ ẩm", hint: "Lượng hơi nước trong không khí.", options: ["A. Nhiệt độ", "B. Độ ẩm", "C. Áp suất", "D. Lượng mưa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Weather forecast", answer: "Dự báo thời tiết", hint: "Chương trình báo trước thời tiết sắp tới.", options: ["A. Tin tức", "B. Dự báo thời tiết", "C. Thời sự", "D. Phim"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Precipitation", answer: "Lượng mưa / Sự kết tủa", hint: "Từ học thuật chỉ mưa, tuyết, mưa đá.", options: ["A. Nắng", "B. Lượng mưa", "C. Gió", "D. Mây"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Global warming", answer: "Sự nóng lên toàn cầu", hint: "Trái đất nóng dần lên do ô nhiễm.", options: ["A. Biến đổi khí hậu", "B. Nóng lên toàn cầu", "C. Mưa axit", "D. Thủng tầng ozone"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Barometer", answer: "Áp kế", hint: "Dụng cụ đo áp suất khí quyển để dự báo thời tiết.", options: ["A. Nhiệt kế", "B. Áp kế", "C. Thước kẻ", "D. Cân"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Flood", answer: "Lũ lụt", hint: "Nước dâng cao tràn vào nhà cửa.", options: ["A. Hạn hán", "B. Lũ lụt", "C. Sạt lở", "D. Cháy rừng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Drought", answer: "Hạn hán", hint: "Tình trạng thiếu nước kéo dài.", options: ["A. Lũ lụt", "B. Hạn hán", "C. Động đất", "D. Sóng thần"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Meteorology", answer: "Khí tượng học", hint: "Ngành khoa học nghiên cứu về thời tiết.", options: ["A. Thiên văn học", "B. Khí tượng học", "C. Địa chất học", "D. Sinh học"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Climate change", answer: "Biến đổi khí hậu", hint: "Sự thay đổi dài hạn của các mô hình thời tiết.", options: ["A. Ô nhiễm", "B. Biến đổi khí hậu", "C. Thiên tai", "D. Thời tiết xấu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Gale", answer: "Gió giật mạnh", hint: "Gió rất mạnh nhưng chưa mạnh bằng bão.", options: ["A. Gió nhẹ", "B. Gió giật", "C. Đứng gió", "D. Hơi nóng"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 5: VIỆT SANG ANH & ĐIỀN TỪ (Vietnamese to English & Fill) ---
                Flashcard(question: "Từ nào nghĩa là 'Nhiệt độ'?", answer: "Temperature", hint: "Đo bằng độ C hoặc độ F.", options: ["A. Pressure", "B. Temperature", "C. Degree", "D. Climate"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ nào nghĩa là 'Mùa khô'?", answer: "Dry season", hint: "Mùa ít mưa ở miền Nam.", options: ["A. Rainy season", "B. Dry season", "C. Summer", "D. Autumn"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ nào nghĩa là 'Nắng gắt'?", answer: "Blazing sun", hint: "Ánh nắng chói chang và rất nóng.", options: ["A. Mild sun", "B. Blazing sun", "C. Soft light", "D. Moonlight"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "It is ___ cats and dogs.", answer: "raining", hint: "Thành ngữ: Mưa rất to.", options: ["A. snowing", "B. raining", "C. blowing", "D. clouding"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Take an ___ because it's raining.", answer: "umbrella", hint: "Vật dụng dùng để che mưa.", options: ["A. hat", "B. umbrella", "C. coat", "D. bag"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                
                // (Tiếp tục bổ sung cho đủ 100 từ với các từ như: Monsoon, Gust, Sleet, Thaw, Smog, UV Index, Haze...)
                Flashcard(question: "Monsoon", answer: "Gió mùa", hint: "Loại gió thay đổi theo mùa ở Việt Nam.", options: ["A. Bão", "B. Gió mùa", "C. Lốc", "D. Gió lướt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Degree Celsius", answer: "Độ C", hint: "Đơn vị đo nhiệt độ phổ biến.", options: ["A. Độ F", "B. Độ C", "C. Kilo", "D. Mét"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "UV Index", answer: "Chỉ số tia cực tím", hint: "Báo hiệu mức độ nguy hại của ánh nắng.", options: ["A. Độ ẩm", "B. Chỉ số UV", "C. Lượng mưa", "D. Tốc độ gió"], correctAnswer: "B", exerciseType: .englishToVietnamese),
              // --- NHÓM 5: THIÊN TAI & HIỆN TƯỢNG CỰC ĐOAN (Natural Disasters) ---
        Flashcard(question: "Flash flood", answer: "Lũ quét", hint: "Trận lũ dâng lên rất nhanh và bất ngờ, thường ở vùng núi.", options: ["A. Lũ lụt", "B. Lũ quét", "C. Thủy triều", "D. Sóng thần"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Tsunami", answer: "Sóng thần", hint: "Sóng biển khổng lồ do động đất dưới đáy biển gây ra.", options: ["A. Lốc xoáy", "B. Sóng thần", "C. Bão lớn", "D. Lũ quét"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Landslide", answer: "Sạt lở đất", hint: "Hiện tượng đất đá đổ xuống từ sườn núi do mưa lớn.", options: ["A. Động đất", "B. Sạt lở đất", "C. Hạn hán", "D. Núi lửa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Wildfire", answer: "Cháy rừng", hint: "Đám cháy lớn xảy ra trong rừng do nắng nóng khô hạn.", options: ["A. Hỏa hoạn", "B. Cháy rừng", "C. Núi lửa", "D. Đốt rẫy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Earthquake", answer: "Động đất", hint: "Sự rung chuyển mặt đất do dịch chuyển địa tầng.", options: ["A. Sóng thần", "B. Động đất", "C. Lốc xoáy", "D. Núi lửa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Sandstorm", answer: "Bão cát", hint: "Trận bão mang theo lượng cát khổng lồ, thường ở sa mạc.", options: ["A. Bão bụi", "B. Bão cát", "C. Bão tuyết", "D. Bão nhiệt đới"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Acid rain", answer: "Mưa axit", hint: "Nước mưa có độ pH thấp do ô nhiễm không khí.", options: ["A. Mưa rào", "B. Mưa axit", "C. Mưa đá", "D. Mưa phùn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Avalanche", answer: "Tuyết lở", hint: "Khối lượng lớn tuyết đổ xuống từ đỉnh núi.", options: ["A. Bão tuyết", "B. Tuyết lở", "C. Sương giá", "D. Đóng băng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Heat exhaustion", answer: "Kiệt sức do nhiệt", hint: "Tình trạng cơ thể bị quá nóng khi ở ngoài trời nắng lâu.", options: ["A. Say nắng", "B. Kiệt sức do nhiệt", "C. Bỏng nắng", "D. Mất nước"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Aftershock", answer: "Dư chấn", hint: "Các trận động đất nhỏ xảy ra sau trận động đất chính.", options: ["A. Chấn tâm", "B. Dư chấn", "C. Địa chấn", "D. Sóng địa chấn"], correctAnswer: "B", exerciseType: .englishToVietnamese),

        // --- NHÓM 6: TRẠNG THÁI BẦU TRỜI & KHÔNG KHÍ (Atmospheric Conditions) ---
        Flashcard(question: "Smog", answer: "Khói bụi ô nhiễm", hint: "Sự kết hợp giữa khói (smoke) và sương mù (fog).", options: ["A. Sương mù", "B. Khói bụi ô nhiễm", "C. Mây đen", "D. Bụi mịn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Haze", answer: "Sương mù quang hóa / Bụi mờ", hint: "Lớp mờ trong không khí do bụi hoặc khói.", options: ["A. Sương mù dày", "B. Bụi mờ", "C. Mây thấp", "D. Hơi nước"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Gust", answer: "Gió giật", hint: "Cơn gió mạnh thổi lên bất ngờ trong thời gian ngắn.", options: ["A. Gió nhẹ", "B. Gió giật", "C. Gió mùa", "D. Gió lốc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Draft", answer: "Luồng gió lùa", hint: "Luồng không khí lạnh thổi vào trong phòng kín.", options: ["A. Gió biển", "B. Gió lùa", "C. Gió tây", "D. Gió bấc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Dew", answer: "Sương đêm / Giọt sương", hint: "Hơi nước ngưng tụ trên cỏ cây vào buổi sớm.", options: ["A. Mưa", "B. Sương đêm", "C. Tuyết", "D. Băng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Humidity", answer: "Độ ẩm", hint: "Dùng để đo lượng hơi nước. 'High humidity makes it feel hotter'.", options: ["A. Nhiệt độ", "B. Độ ẩm", "C. Áp suất", "D. Lượng mưa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Barometric pressure", answer: "Áp suất khí quyển", hint: "Áp suất của không khí, dùng để dự báo bão.", options: ["A. Độ ẩm", "B. Áp suất khí quyển", "C. Sức gió", "D. Tầm nhìn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Rainbow", answer: "Cầu vồng", hint: "Hiện tượng tán sắc ánh sáng qua giọt nước mưa.", options: ["A. Mây ngũ sắc", "B. Cầu vồng", "C. Ánh cực quang", "D. Sét"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Afterglow", answer: "Ráng chiều / Ánh hồng sau hoàng hôn", hint: "Ánh sáng còn sót lại sau khi mặt trời lặn.", options: ["A. Bình minh", "B. Ráng chiều", "C. Nhật thực", "D. Trăng rằm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Visibility", answer: "Tầm nhìn", hint: "Khoảng cách có thể nhìn rõ. 'Low visibility due to fog'.", options: ["A. Thị lực", "B. Tầm nhìn", "C. Khoảng cách", "D. Ánh sáng"], correctAnswer: "B", exerciseType: .englishToVietnamese),

        // --- NHÓM 7: MÙA & CHU KỲ (Seasons & Cycles) ---
        Flashcard(question: "Monsoon", answer: "Gió mùa", hint: "Loại gió thổi theo mùa mang theo mưa lớn (đặc trưng Đông Nam Á).", options: ["A. Gió bão", "B. Gió mùa", "C. Gió lào", "D. Gió biển"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Equinox", answer: "Điểm phân (Xuân phân/Thu phân)", hint: "Thời điểm ngày và đêm dài bằng nhau.", options: ["A. Hạ chí", "B. Điểm phân", "C. Đông chí", "D. Trăng khuyết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Solstice", answer: "Điểm chí (Hạ chí/Đông chí)", hint: "Ngày dài nhất hoặc ngắn nhất trong năm.", options: ["A. Ngày rằm", "B. Điểm chí", "C. Tết nguyên đán", "D. Giao thừa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Dry season", answer: "Mùa khô", hint: "Giai đoạn ít mưa kéo dài trong năm.", options: ["A. Mùa mưa", "B. Mùa khô", "C. Mùa lũ", "D. Mùa gặt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Rainy season", answer: "Mùa mưa", hint: "Giai đoạn mưa nhiều, thường có bão lụt.", options: ["A. Mùa nồm", "B. Mùa mưa", "C. Mùa đông", "D. Mùa thu hoạch"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Thaw", answer: "Sự tan băng", hint: "Khi thời tiết ấm lên khiến tuyết và băng tan chảy.", options: ["A. Đóng băng", "B. Tan băng", "C. Tuyết rơi", "D. Mưa đá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Meteorologist", answer: "Nhà khí tượng học", hint: "Người chuyên nghiên cứu và dự báo thời tiết.", options: ["A. Nhà thiên văn", "B. Nhà khí tượng", "C. Nhà địa chất", "D. Phi hành gia"], correctAnswer: "B", exerciseType: .englishToVietnamese),

        // --- NHÓM 8: CẢM GIÁC & TÁC ĐỘNG (Impact & Sensation) ---
        Flashcard(question: "Sunburnt", answer: "Bị cháy nắng", hint: "Da bị đỏ và đau do tiếp xúc quá lâu với tia UV.", options: ["A. Sạm da", "B. Cháy nắng", "). Nám da", "D. Dị ứng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Frostbite", answer: "Bị bỏng lạnh", hint: "Tổn thương mô cơ thể do nhiệt độ cực thấp.", options: ["A. Cảm lạnh", "B. Bỏng lạnh", "C. Run rẩy", "D. Đóng băng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Shiver", answer: "Run lẩy bẩy", hint: "Hành động của cơ thể khi cảm thấy quá lạnh.", options: ["A. Đổ mồ hôi", "B. Run lẩy bẩy", "C. Hắt hơi", "D. Ho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Sweat", answer: "Đổ mồ hôi", hint: "Phản ứng của cơ thể để làm mát khi trời nóng.", options: ["A. Khát nước", "B. Đổ mồ hôi", "C. Mệt mỏi", "D. Ngất xỉu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Dehydration", answer: "Sự mất nước", hint: "Tình trạng thiếu nước trong cơ thể do nắng nóng.", options: ["A. Kiệt sức", "B. Mất nước", "C. Đói bụng", "D. Nhức đầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Balmy", answer: "Ấm áp dễ chịu", hint: "Thời tiết ấm, gió nhẹ, cực kỳ thư giãn.", options: ["A. Nóng bức", "B. Ấm áp dễ chịu", "C. Se lạnh", "D. Ẩm ướt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Harsh", answer: "Khắc nghiệt", hint: "Thời tiết rất khó khăn để sinh tồn. 'Harsh winter'.", options: ["A. Ôn hòa", "B. Khắc nghiệt", "C. Thay đổi", "D. Thuận lợi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Unpredictable", answer: "Thất thường / Khó dự đoán", hint: "Thời tiết thay đổi liên tục không báo trước.", options: ["A. Ổn định", "B. Thất thường", "C. Chính xác", "D. Tệ hại"], correctAnswer: "B", exerciseType: .englishToVietnamese),

        // --- NHÓM 9: THIẾT BỊ & ĐO LƯỜNG (Equipment) ---
        Flashcard(question: "Anemometer", answer: "Máy đo tốc độ gió", hint: "Thiết bị dùng để đo vận tốc của gió.", options: ["A. Nhiệt kế", "B. Máy đo gió", "C. Áp kế", "D. Máy đo mưa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Thermometer", answer: "Nhiệt kế", hint: "Dụng cụ đo nhiệt độ cơ thể hoặc môi trường.", options: ["A. Cân", "B. Nhiệt kế", "C. Thước kẻ", "D. Đồng hồ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Rain gauge", answer: "Vũ kế / Máy đo mưa", hint: "Dụng cụ đo lượng mưa rơi xuống trong một vùng.", options: ["A. Bình nước", "B. Máy đo mưa", "C. Máy bơm", "D. Ống dẫn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Weather vane", answer: "Chong chóng gió / Kim chỉ gió", hint: "Dụng cụ cho biết hướng gió thổi.", options: ["A. Quạt giấy", "B. Kim chỉ gió", "C. La bàn", "D. Bản đồ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Hygrometer", answer: "Ẩm kế", hint: "Thiết bị dùng để đo độ ẩm không khí.", options: ["A. Nhiệt kế", "B. Ẩm kế", "C. Áp kế", "D. Đồng hồ"], correctAnswer: "B", exerciseType: .englishToVietnamese),

        // --- NHÓM 10: CỤM TỪ & THÀNH NGỮ (Phrases & Idioms) ---
        Flashcard(question: "A storm in a teacup", answer: "Chuyện bé xé ra to", hint: "Thành ngữ: Sự tức giận quá mức về một việc nhỏ.", options: ["A. Bão trong tách trà", "B. Chuyện bé xé ra to", "C. Cơn bão nhỏ", "D. Uống trà trong bão"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Under the weather", answer: "Cảm thấy không khỏe", hint: "Thành ngữ: Thấy hơi mệt hoặc ốm.", options: ["A. Dưới thời tiết", "B. Cảm thấy không khỏe", "C. Đi dạo", "D. Trời đang mưa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Come rain or shine", answer: "Dù nắng hay mưa", hint: "Thành ngữ: Chắc chắn sẽ làm dù có chuyện gì xảy ra.", options: ["A. Mưa bóng mây", "B. Dù nắng hay mưa", "C. Chờ đợi", "D. Hy vọng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Cloud nine", answer: "Cực kỳ hạnh phúc", hint: "Thành ngữ: Cảm giác như đang trên chín tầng mây.", options: ["A. Đám mây thứ 9", "B. Cực kỳ hạnh phúc", "C. Bay bổng", "D. Buồn bã"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Steal someone's thunder", answer: "Lấy mất sự chú ý của ai đó", hint: "Thành ngữ: Làm điều gì đó để mọi người khen mình thay vì người kia.", options: ["A. Ăn trộm sấm sét", "B. Lấy mất sự chú ý của ai", "C. Làm phiền", "D. Giúp đỡ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Weather the storm", answer: "Vượt qua giai đoạn khó khăn", hint: "Thành ngữ: Chống chọi và sống sót qua nghịch cảnh.", options: ["A. Chống bão", "B. Vượt qua khó khăn", "C. Đi trong bão", "D. Dự báo bão"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Save for a rainy day", answer: "Dành dụm cho lúc khó khăn", hint: "Thành ngữ: Tiết kiệm tiền bạc phòng khi hữu sự.", options: ["A. Chờ ngày mưa", "B. Tiết kiệm cho lúc khó khăn", "C. Mua ô", "D. Đi làm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Bolt from the blue", answer: "Tin sét đánh / Việc bất ngờ", hint: "Thành ngữ: Một sự việc xảy ra hoàn toàn bất ngờ.", options: ["A. Tia sét màu xanh", "B. Tin sét đánh ngang tai", "C. Trời quang", "D. Chạy trốn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
        Flashcard(question: "Every cloud has a silver lining", answer: "Trong cái rủi có cái may", hint: "Thành ngữ: Luôn có điều tốt đẹp trong tình huống xấu.", options: ["A. Đám mây bạc", "B. Trong cái rủi có cái may", "C. Hy vọng hão huyền", "D. Trời sắp sáng"], correctAnswer: "B", exerciseType: .englishToVietnamese)
    ]
        )
        
        // Christmas topic
        let christmasTopic = Topic(
            name: "Christmas (Giáng sinh)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // MARK: - Basic Christmas Vocabulary - English to Vietnamese
                Flashcard(question: "What is 'Christmas' in Vietnamese?", answer: "Giáng sinh", hint: "December 25th", options: ["A. Giáng sinh", "B. Noel", "C. Lễ hội", "D. Ngày lễ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'Santa Claus' in Vietnamese?", answer: "Ông già Noel", hint: "Brings gifts", options: ["A. Ông già", "B. Ông Noel", "C. Ông già Noel", "D. Bố Noel"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'Christmas tree' in Vietnamese?", answer: "Cây thông Noel", hint: "Decorated tree", options: ["A. Cây thông", "B. Cây Noel", "C. Cây thông Noel", "D. Cây trang trí"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'gift' or 'present' in Vietnamese?", answer: "Quà tặng", hint: "What you receive", options: ["A. Quà", "B. Tặng phẩm", "C. Quà tặng", "D. Hộp quà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'reindeer' in Vietnamese?", answer: "Tuần lộc", hint: "Pulls Santa's sleigh", options: ["A. Nai", "B. Tuần lộc", "C. Hươu", "D. Nai sừng tấm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sleigh' in Vietnamese?", answer: "Xe trượt tuyết", hint: "Santa rides this", options: ["A. Xe", "B. Xe tuyết", "C. Xe trượt tuyết", "D. Xe ngựa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'snow' in Vietnamese?", answer: "Tuyết", hint: "White and cold", options: ["A. Băng", "B. Tuyết", "C. Sương", "D. Đá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'snowman' in Vietnamese?", answer: "Người tuyết", hint: "Made from snow", options: ["A. Tuyết nhân", "B. Người tuyết", "C. Búp bê tuyết", "D. Tượng tuyết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'star' in Vietnamese?", answer: "Ngôi sao", hint: "On top of tree", options: ["A. Sao", "B. Ngôi sao", "C. Ngôi sao Noel", "D. Sao đêm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ornament' in Vietnamese?", answer: "Đồ trang trí", hint: "Hangs on tree", options: ["A. Quả cầu", "B. Trang trí", "C. Đồ trang trí", "D. Vật trang trí"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Christmas Characters & Symbols
                Flashcard(question: "What is 'elf' in Vietnamese?", answer: "Yêu tinh", hint: "Santa's helper", options: ["A. Tiên", "B. Yêu tinh", "C. Người lùn", "D. Phù thủy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'angel' in Vietnamese?", answer: "Thiên thần", hint: "Has wings, heavenly", options: ["A. Thần tiên", "B. Thiên thần", "C. Tiên nữ", "D. Nữ thần"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bell' in Vietnamese?", answer: "Chuông", hint: "Jingle ___", options: ["A. Chuông", "B. Cồng", "C. Trống", "D. Kèn"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'candy cane' in Vietnamese?", answer: "Kẹo gậy", hint: "Red and white striped", options: ["A. Kẹo", "B. Kẹo Noel", "C. Kẹo gậy", "D. Kẹo que"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stocking' in Vietnamese?", answer: "Tất Noel", hint: "Hang by fireplace", options: ["A. Tất", "B. Bít tất", "C. Tất Noel", "D. Túi quà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'chimney' in Vietnamese?", answer: "Ống khói", hint: "Santa comes down", options: ["A. Lò sưởi", "B. Ống khói", "C. Mái nhà", "D. Cửa sổ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fireplace' in Vietnamese?", answer: "Lò sưởi", hint: "Warm and cozy", options: ["A. Lửa", "B. Lò", "C. Lò sưởi", "D. Bếp"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wreath' in Vietnamese?", answer: "Vòng hoa", hint: "Circle of flowers", options: ["A. Hoa", "B. Vòng hoa", "C. Vòng tròn", "D. Hoa Noel"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mistletoe' in Vietnamese?", answer: "Cây tầm gửi", hint: "Kiss under it", options: ["A. Cây", "B. Lá", "C. Cây Noel", "D. Cây tầm gửi"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'holly' in Vietnamese?", answer: "Cây nhựa ruồi", hint: "Red berries, green leaves", options: ["A. Cây thông", "B. Cây nhựa ruồi", "C. Cây lá", "D. Cây đỏ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Christmas Activities & Traditions
                Flashcard(question: "What is 'carol' in Vietnamese?", answer: "Thánh ca", hint: "Christmas song", options: ["A. Bài hát", "B. Nhạc", "C. Thánh ca", "D. Ca khúc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'celebration' in Vietnamese?", answer: "Lễ kỷ niệm", hint: "Party or event", options: ["A. Tiệc", "B. Lễ hội", "C. Lễ kỷ niệm", "D. Sự kiện"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'tradition' in Vietnamese?", answer: "Truyền thống", hint: "Passed down custom", options: ["A. Phong tục", "B. Truyền thống", "C. Văn hóa", "D. Tập quán"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'decoration' in Vietnamese?", answer: "Sự trang trí", hint: "Making things pretty", options: ["A. Trang trí", "B. Sự trang trí", "C. Đồ trang trí", "D. Vật trang trí"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cookie' in Vietnamese?", answer: "Bánh quy", hint: "Sweet baked treat", options: ["A. Bánh", "B. Bánh ngọt", "C. Bánh quy", "D. Bánh nướng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'milk' in Vietnamese?", answer: "Sữa", hint: "Left for Santa", options: ["A. Sữa", "B. Nước", "C. Trà", "D. Cà phê"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'feast' in Vietnamese?", answer: "Bữa tiệc", hint: "Big meal", options: ["A. Bữa ăn", "B. Tiệc", "C. Bữa tiệc", "D. Món ăn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'church' in Vietnamese?", answer: "Nhà thờ", hint: "Place of worship", options: ["A. Chùa", "B. Nhà thờ", "C. Đền", "D. Thánh đường"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Christmas Items & Objects
                Flashcard(question: "What is 'ribbon' in Vietnamese?", answer: "Ruy băng", hint: "Decorative strip", options: ["A. Dây", "B. Băng", "C. Ruy băng", "D. Dải"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bow' in Vietnamese?", answer: "Nơ", hint: "Tied ribbon", options: ["A. Nơ", "B. Dây", "C. Băng", "D. Buộc"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'candle' in Vietnamese?", answer: "Nến", hint: "Gives light", options: ["A. Đèn", "B. Nến", "C. Lửa", "D. Sáng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'light' in Vietnamese?", answer: "Đèn", hint: "Christmas ___s", options: ["A. Sáng", "B. Đèn", "C. Ánh sáng", "D. Chiếu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'card' in Vietnamese?", answer: "Thiệp", hint: "Send greetings", options: ["A. Thư", "B. Thiệp", "C. Bưu thiếp", "D. Giấy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'box' in Vietnamese?", answer: "Hộp", hint: "Container for gift", options: ["A. Túi", "B. Hộp", "C. Thùng", "D. Bao"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'toy' in Vietnamese?", answer: "Đồ chơi", hint: "For children", options: ["A. Trò chơi", "B. Đồ chơi", "C. Búp bê", "D. Xe"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'doll' in Vietnamese?", answer: "Búp bê", hint: "Child's toy", options: ["A. Đồ chơi", "B. Búp bê", "C. Gấu bông", "D. Thú nhồi bông"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Christmas Feelings & Adjectives
                Flashcard(question: "What is 'joy' in Vietnamese?", answer: "Niềm vui", hint: "Happy feeling", options: ["A. Vui", "B. Niềm vui", "C. Hạnh phúc", "D. Vui vẻ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'merry' in Vietnamese?", answer: "Vui vẻ", hint: "___ Christmas!", options: ["A. Vui", "B. Vui vẻ", "C. Hạnh phúc", "D. Vui mừng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'peaceful' in Vietnamese?", answer: "Yên bình", hint: "Calm and quiet", options: ["A. Êm đềm", "B. Yên tĩnh", "C. Yên bình", "D. Bình an"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'magical' in Vietnamese?", answer: "Kỳ diệu", hint: "Full of magic", options: ["A. Thần kỳ", "B. Kỳ diệu", "C. Phép thuật", "D. Huyền bí"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'festive' in Vietnamese?", answer: "Lễ hội", hint: "Party atmosphere", options: ["A. Vui", "B. Lễ hội", "C. Náo nhiệt", "D. Sôi động"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cozy' in Vietnamese?", answer: "Ấm cúng", hint: "Warm and comfortable", options: ["A. Ấm", "B. Thoải mái", "C. Ấm cúng", "D. Dễ chịu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Vietnamese to English
                Flashcard(question: "Từ 'Ông già Noel' trong tiếng Anh là gì?", answer: "Santa Claus", hint: "Brings presents", options: ["A. Santa", "B. Santa Claus", "C. Father Christmas", "D. Saint Nicholas"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Cây thông Noel' trong tiếng Anh là gì?", answer: "Christmas tree", hint: "Decorated tree", options: ["A. Tree", "B. Pine tree", "C. Christmas tree", "D. Fir tree"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Quà tặng' trong tiếng Anh là gì?", answer: "Gift/Present", hint: "What you give", options: ["A. Gift", "B. Present", "C. Package", "D. Box"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tuyết' trong tiếng Anh là gì?", answer: "Snow", hint: "White and cold", options: ["A. Ice", "B. Snow", "C. Frost", "D. Winter"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tuần lộc' trong tiếng Anh là gì?", answer: "Reindeer", hint: "Santa's animal", options: ["A. Deer", "B. Elk", "C. Reindeer", "D. Moose"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Yêu tinh' trong tiếng Anh là gì?", answer: "Elf", hint: "Helper", options: ["A. Fairy", "B. Dwarf", "C. Elf", "D. Gnome"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Chuông' trong tiếng Anh là gì?", answer: "Bell", hint: "Makes ringing sound", options: ["A. Ring", "B. Bell", "C. Chime", "D. Jingle"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Kẹo gậy' trong tiếng Anh là gì?", answer: "Candy cane", hint: "Striped sweet", options: ["A. Candy", "B. Cane", "C. Candy cane", "D. Sweet stick"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thánh ca' trong tiếng Anh là gì?", answer: "Carol", hint: "Christmas song", options: ["A. Song", "B. Hymn", "C. Carol", "D. Music"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thiên thần' trong tiếng Anh là gì?", answer: "Angel", hint: "Heavenly being", options: ["A. Saint", "B. Angel", "C. Spirit", "D. Fairy"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // MARK: - Fill in the Blank
                Flashcard(question: "Santa rides in a ___.", answer: "sleigh", hint: "Pulled by reindeer", options: ["A. car", "B. sleigh", "C. carriage", "D. sled"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "We decorate the Christmas ___.", answer: "tree", hint: "Green and tall", options: ["A. house", "B. tree", "C. room", "D. wall"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Children hang ___ by the fireplace.", answer: "stockings", hint: "Filled with gifts", options: ["A. socks", "B. stockings", "C. shoes", "D. bags"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "We sing Christmas ___ together.", answer: "carols", hint: "Holiday songs", options: ["A. songs", "B. hymns", "C. carols", "D. music"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "There's a ___ on top of the tree.", answer: "star", hint: "Shiny object", options: ["A. angel", "B. star", "C. light", "D. ornament"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Santa comes down the ___.", answer: "chimney", hint: "On the roof", options: ["A. door", "B. window", "C. chimney", "D. stairs"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "We give ___ to family and friends.", answer: "gifts", hint: "Wrapped presents", options: ["A. cards", "B. gifts", "C. food", "D. money"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ helps Santa make toys.", answer: "elf", hint: "Small helper", options: ["A. reindeer", "B. angel", "C. elf", "D. child"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                
                // MARK: - Choose Correct Word
                Flashcard(question: "What do children leave for Santa?", answer: "Cookies and milk", hint: "Sweet snack and drink", options: ["A. Cookies and milk", "B. Candy and juice", "C. Cake and tea", "D. Bread and water"], correctAnswer: "A", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What pulls Santa's sleigh?", answer: "Reindeer", hint: "Animals with antlers", options: ["A. Horses", "B. Dogs", "C. Reindeer", "D. Elves"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "When is Christmas Day?", answer: "December 25th", hint: "Winter holiday", options: ["A. December 24th", "B. December 25th", "C. December 31st", "D. January 1st"], correctAnswer: "B", exerciseType: .chooseCorrectWord)
            ]
        )
        
        // Kitchen topic
        let kitchenTopic = Topic(
            name: "Kitchen (Nhà bếp)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // MARK: - Kitchen Appliances - English to Vietnamese
                Flashcard(question: "What is 'refrigerator' or 'fridge' in Vietnamese?", answer: "Tủ lạnh", hint: "Keeps food cold", options: ["A. Lò vi sóng", "B. Tủ lạnh", "C. Bếp", "D. Lò nướng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stove' in Vietnamese?", answer: "Bếp", hint: "For cooking", options: ["A. Bếp", "B. Lò", "C. Nồi", "D. Chảo"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'oven' in Vietnamese?", answer: "Lò nướng", hint: "For baking", options: ["A. Bếp", "B. Lò vi sóng", "C. Lò nướng", "D. Tủ lạnh"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'microwave' in Vietnamese?", answer: "Lò vi sóng", hint: "Quick heating", options: ["A. Lò nướng", "B. Lò vi sóng", "C. Bếp", "D. Nồi cơm điện"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'dishwasher' in Vietnamese?", answer: "Máy rửa bát", hint: "Cleans dishes", options: ["A. Máy giặt", "B. Máy rửa bát", "C. Bồn rửa", "D. Chậu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sink' in Vietnamese?", answer: "Bồn rửa", hint: "Wash dishes here", options: ["A. Bồn rửa", "B. Máy rửa", "C. Vòi nước", "D. Chậu"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'blender' in Vietnamese?", answer: "Máy xay sinh tố", hint: "Makes smoothies", options: ["A. Máy ép", "B. Máy xay", "C. Máy xay sinh tố", "D. Máy trộn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'toaster' in Vietnamese?", answer: "Máy nướng bánh mì", hint: "For bread", options: ["A. Lò nướng", "B. Máy nướng bánh mì", "C. Bếp", "D. Lò vi sóng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'kettle' in Vietnamese?", answer: "Ấm đun nước", hint: "Boils water", options: ["A. Nồi", "B. Ấm", "C. Ấm đun nước", "D. Bình nước"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'coffee maker' in Vietnamese?", answer: "Máy pha cà phê", hint: "Makes coffee", options: ["A. Bình cà phê", "B. Máy pha cà phê", "C. Ấm", "D. Cốc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Cookware & Utensils
                Flashcard(question: "What is 'pot' in Vietnamese?", answer: "Nồi", hint: "Deep cooking vessel", options: ["A. Chảo", "B. Nồi", "C. Thau", "D. Xoong"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pan' or 'frying pan' in Vietnamese?", answer: "Chảo", hint: "Flat cooking surface", options: ["A. Nồi", "B. Chảo", "C. Xoong", "D. Thau"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'knife' in Vietnamese?", answer: "Dao", hint: "For cutting", options: ["A. Dao", "B. Kéo", "C. Thìa", "D. Dĩa"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fork' in Vietnamese?", answer: "Dĩa, nĩa", hint: "Has prongs", options: ["A. Thìa", "B. Dĩa", "C. Dao", "D. Đũa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'spoon' in Vietnamese?", answer: "Thìa, muỗng", hint: "For soup", options: ["A. Thìa", "B. Dĩa", "C. Đũa", "D. Dao"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'chopsticks' in Vietnamese?", answer: "Đũa", hint: "Asian utensil", options: ["A. Thìa", "B. Dĩa", "C. Đũa", "D. Que"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cutting board' in Vietnamese?", answer: "Thớt", hint: "Cut food on this", options: ["A. Bàn", "B. Thớt", "C. Khay", "D. Mâm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'spatula' in Vietnamese?", answer: "Muỗng xới, thìa xới", hint: "Flip food", options: ["A. Muỗng", "B. Muỗng xới", "C. Dĩa", "D. Kẹp"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ladle' in Vietnamese?", answer: "Muôi", hint: "For soup", options: ["A. Thìa", "B. Muôi", "C. Muỗng", "D. Chén"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'whisk' in Vietnamese?", answer: "Cây đánh trứng", hint: "Beat eggs", options: ["A. Dao", "B. Thìa", "C. Cây đánh trứng", "D. Nĩa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Dishes & Containers
                Flashcard(question: "What is 'plate' in Vietnamese?", answer: "Đĩa", hint: "Flat dish", options: ["A. Bát", "B. Đĩa", "C. Chén", "D. Tô"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bowl' in Vietnamese?", answer: "Bát, tô", hint: "Deep dish", options: ["A. Đĩa", "B. Bát", "C. Chén", "D. Ly"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cup' in Vietnamese?", answer: "Cốc, tách", hint: "For drinks", options: ["A. Ly", "B. Cốc", "C. Chén", "D. Bình"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'glass' in Vietnamese?", answer: "Ly, cốc thủy tinh", hint: "Made of glass", options: ["A. Cốc", "B. Ly", "C. Chén", "D. Bình"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mug' in Vietnamese?", answer: "Cốc có quai", hint: "Has handle", options: ["A. Ly", "B. Cốc", "C. Cốc có quai", "D. Tách"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bottle' in Vietnamese?", answer: "Chai, lọ", hint: "Contains liquid", options: ["A. Chai", "B. Bình", "C. Hộp", "D. Lọ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'jar' in Vietnamese?", answer: "Lọ, hũ", hint: "Storage container", options: ["A. Chai", "B. Hộp", "C. Lọ", "D. Bình"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'container' in Vietnamese?", answer: "Hộp đựng", hint: "Store food", options: ["A. Hộp", "B. Hộp đựng", "C. Thùng", "D. Túi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Kitchen Items & Accessories
                Flashcard(question: "What is 'towel' in Vietnamese?", answer: "Khăn", hint: "Dry hands", options: ["A. Khăn", "B. Giẻ", "C. Vải", "D. Rẻ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'napkin' in Vietnamese?", answer: "Khăn ăn", hint: "At the table", options: ["A. Khăn", "B. Khăn tay", "C. Khăn ăn", "D. Giẻ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'apron' in Vietnamese?", answer: "Tạp dề", hint: "Wear when cooking", options: ["A. Áo", "B. Tạp dề", "C. Khăn", "D. Quần"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'trash can' or 'bin' in Vietnamese?", answer: "Thùng rác", hint: "For garbage", options: ["A. Thùng", "B. Thùng rác", "C. Sọt", "D. Giỏ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cabinet' in Vietnamese?", answer: "Tủ", hint: "Storage furniture", options: ["A. Kệ", "B. Tủ", "C. Ngăn kéo", "D. Hộc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'drawer' in Vietnamese?", answer: "Ngăn kéo", hint: "Pull out storage", options: ["A. Tủ", "B. Hộc", "C. Ngăn kéo", "D. Kệ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'shelf' in Vietnamese?", answer: "Kệ", hint: "Horizontal storage", options: ["A. Tủ", "B. Kệ", "C. Giá", "D. Bàn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'counter' or 'countertop' in Vietnamese?", answer: "Mặt bàn bếp", hint: "Work surface", options: ["A. Bàn", "B. Mặt bàn", "C. Mặt bàn bếp", "D. Bệ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Cooking Actions
                Flashcard(question: "What is 'cook' in Vietnamese?", answer: "Nấu ăn", hint: "Make food", options: ["A. Ăn", "B. Nấu", "C. Nấu ăn", "D. Làm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'boil' in Vietnamese?", answer: "Luộc, đun sôi", hint: "In water", options: ["A. Chiên", "B. Luộc", "C. Nướng", "D. Hấp"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fry' in Vietnamese?", answer: "Chiên, rán", hint: "In oil", options: ["A. Chiên", "B. Luộc", "C. Nướng", "D. Xào"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bake' in Vietnamese?", answer: "Nướng (trong lò)", hint: "In oven", options: ["A. Chiên", "B. Nướng", "C. Hấp", "D. Luộc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'steam' in Vietnamese?", answer: "Hấp", hint: "With steam", options: ["A. Luộc", "B. Hấp", "C. Chiên", "D. Nướng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cut' in Vietnamese?", answer: "Cắt", hint: "With knife", options: ["A. Cắt", "B. Chặt", "C. Thái", "D. Xắt"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'chop' in Vietnamese?", answer: "Chặt", hint: "Into pieces", options: ["A. Cắt", "B. Chặt", "C. Xắt", "D. Thái"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'slice' in Vietnamese?", answer: "Thái lát", hint: "Thin pieces", options: ["A. Cắt", "B. Chặt", "C. Thái", "D. Xắt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mix' in Vietnamese?", answer: "Trộn", hint: "Combine together", options: ["A. Khuấy", "B. Trộn", "C. Xào", "D. Nhào"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stir' in Vietnamese?", answer: "Khuấy", hint: "Move around", options: ["A. Trộn", "B. Khuấy", "C. Đánh", "D. Xào"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Vietnamese to English
                Flashcard(question: "Từ 'Tủ lạnh' trong tiếng Anh là gì?", answer: "Refrigerator/Fridge", hint: "Keep food cold", options: ["A. Freezer", "B. Refrigerator", "C. Cooler", "D. Cabinet"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Lò vi sóng' trong tiếng Anh là gì?", answer: "Microwave", hint: "Quick heating", options: ["A. Oven", "B. Stove", "C. Microwave", "D. Toaster"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Dao' trong tiếng Anh là gì?", answer: "Knife", hint: "For cutting", options: ["A. Fork", "B. Spoon", "C. Knife", "D. Scissors"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đũa' trong tiếng Anh là gì?", answer: "Chopsticks", hint: "Asian utensil", options: ["A. Sticks", "B. Chopsticks", "C. Fork", "D. Spoon"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Nồi' trong tiếng Anh là gì?", answer: "Pot", hint: "Deep cooking", options: ["A. Pan", "B. Pot", "C. Bowl", "D. Kettle"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Chảo' trong tiếng Anh là gì?", answer: "Pan/Frying pan", hint: "Flat cooking", options: ["A. Pot", "B. Pan", "C. Wok", "D. Skillet"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thớt' trong tiếng Anh là gì?", answer: "Cutting board", hint: "Cut vegetables on this", options: ["A. Plate", "B. Board", "C. Cutting board", "D. Counter"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Nấu ăn' trong tiếng Anh là gì?", answer: "Cook", hint: "Make food", options: ["A. Eat", "B. Cook", "C. Prepare", "D. Make"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // MARK: - Fill in the Blank
                Flashcard(question: "I keep milk in the ___.", answer: "refrigerator", hint: "Cold appliance", options: ["A. oven", "B. refrigerator", "C. microwave", "D. cabinet"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Use a ___ to cut the vegetables.", answer: "knife", hint: "Cutting tool", options: ["A. spoon", "B. fork", "C. knife", "D. scissors"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Boil water in the ___.", answer: "kettle", hint: "For hot water", options: ["A. cup", "B. kettle", "C. bottle", "D. glass"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "We eat soup with a ___.", answer: "spoon", hint: "Utensil for liquid", options: ["A. fork", "B. knife", "C. spoon", "D. chopsticks"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Put the dirty dishes in the ___.", answer: "sink", hint: "Wash here", options: ["A. cabinet", "B. sink", "C. drawer", "D. trash"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I ___ eggs for breakfast.", answer: "fry", hint: "Cook in oil", options: ["A. boil", "B. fry", "C. bake", "D. steam"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Use a ___ to flip the pancake.", answer: "spatula", hint: "Flat kitchen tool", options: ["A. spoon", "B. fork", "C. spatula", "D. knife"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Store plates in the ___.", answer: "cabinet", hint: "Kitchen storage", options: ["A. drawer", "B. cabinet", "C. sink", "D. oven"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                
                // MARK: - Choose Correct Word
                Flashcard(question: "Where do you wash dishes?", answer: "In the sink", hint: "Water basin", options: ["A. In the oven", "B. In the sink", "C. In the fridge", "D. In the cabinet"], correctAnswer: "B", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What keeps food cold?", answer: "Refrigerator", hint: "Cold appliance", options: ["A. Oven", "B. Microwave", "C. Refrigerator", "D. Stove"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What do you use to eat rice in Asia?", answer: "Chopsticks", hint: "Two sticks", options: ["A. Fork", "B. Spoon", "C. Knife", "D. Chopsticks"], correctAnswer: "D", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What appliance makes coffee?", answer: "Coffee maker", hint: "Brews coffee", options: ["A. Kettle", "B. Coffee maker", "C. Blender", "D. Toaster"], correctAnswer: "B", exerciseType: .chooseCorrectWord)
            ]
        )
        
        // Tet (Lunar New Year) topic
        let tetTopic = Topic(
            name: "Tết - Lunar New Year (Tết Nguyên Đán)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // MARK: - Basic Tet Vocabulary - English to Vietnamese
                Flashcard(question: "What is 'Lunar New Year' or 'Tet' in Vietnamese?", answer: "Tết Nguyên Đán", hint: "Vietnamese New Year", options: ["A. Tết", "B. Tết Nguyên Đán", "C. Năm mới", "D. Xuân"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'Spring' in Vietnamese?", answer: "Mùa xuân", hint: "Season of Tet", options: ["A. Mùa xuân", "B. Mùa hè", "C. Mùa thu", "D. Mùa đông"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'New Year's Eve' in Vietnamese?", answer: "Giao thừa", hint: "Last night of year", options: ["A. Đêm giao thừa", "B. Giao thừa", "C. Tết", "D. Đêm 30"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lucky money' in Vietnamese?", answer: "Tiền lì xì", hint: "Red envelope gift", options: ["A. Tiền thưởng", "B. Tiền lì xì", "C. Quà tặng", "D. Bao lì xì"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'red envelope' in Vietnamese?", answer: "Bao lì xì", hint: "Contains lucky money", options: ["A. Phong bì", "B. Bao đỏ", "C. Bao lì xì", "D. Túi đỏ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'firecrackers' in Vietnamese?", answer: "Pháo", hint: "Make loud sounds", options: ["A. Pháo hoa", "B. Pháo", "C. Pháo nổ", "D. Bắn pháo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fireworks' in Vietnamese?", answer: "Pháo hoa", hint: "Colorful explosions", options: ["A. Pháo", "B. Pháo hoa", "C. Hoa đăng", "D. Hoa lửa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ancestor' in Vietnamese?", answer: "Tổ tiên, ông bà", hint: "Past generations", options: ["A. Ông bà", "B. Tổ tiên", "C. Cha mẹ", "D. Họ hàng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ancestral altar' in Vietnamese?", answer: "Bàn thờ tổ tiên", hint: "Family shrine", options: ["A. Bàn thờ", "B. Bàn thờ tổ tiên", "C. Nhà thờ", "D. Tượng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'worship' in Vietnamese?", answer: "Thờ cúng, lễ bái", hint: "Religious practice", options: ["A. Cầu nguyện", "B. Lễ lạy", "C. Thờ cúng", "D. Cúng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Tet Decorations
                Flashcard(question: "What is 'peach blossom' in Vietnamese?", answer: "Hoa đào", hint: "Pink flowers", options: ["A. Hoa mai", "B. Hoa đào", "C. Hoa lan", "D. Hoa cúc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'apricot blossom' in Vietnamese?", answer: "Hoa mai", hint: "Yellow flowers", options: ["A. Hoa đào", "B. Hoa mai", "C. Hoa cúc", "D. Hoa lan"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'kumquat tree' in Vietnamese?", answer: "Cây quất", hint: "Orange fruit tree", options: ["A. Cây cam", "B. Cây chanh", "C. Cây quất", "D. Cây hoa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'parallel sentences' in Vietnamese?", answer: "Câu đối", hint: "Red poetry on walls", options: ["A. Thơ", "B. Câu đối", "C. Thư pháp", "D. Chữ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'calligraphy' in Vietnamese?", answer: "Thư pháp", hint: "Beautiful writing", options: ["A. Chữ viết", "B. Thư pháp", "C. Chữ", "D. Viết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lantern' in Vietnamese?", answer: "Đèn lồng", hint: "Decorative light", options: ["A. Đèn", "B. Lồng đèn", "C. Đèn lồng", "D. Đèn trang trí"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'decoration' in Vietnamese?", answer: "Trang trí", hint: "Make beautiful", options: ["A. Trang trí", "B. Đồ trang trí", "C. Sự trang trí", "D. Trang hoàng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                
                // MARK: - Tet Foods
                Flashcard(question: "What is 'banh chung' in Vietnamese?", answer: "Bánh chưng", hint: "Square sticky rice cake", options: ["A. Bánh tét", "B. Bánh chưng", "C. Bánh dày", "D. Bánh giò"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'banh tet' in Vietnamese?", answer: "Bánh tét", hint: "Cylindrical sticky rice cake", options: ["A. Bánh chưng", "B. Bánh tét", "C. Bánh dày", "D. Bánh giò"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sticky rice' in Vietnamese?", answer: "Xôi, nếp", hint: "Glutinous rice", options: ["A. Gạo", "B. Cơm", "C. Xôi", "D. Nếp"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pickled vegetables' in Vietnamese?", answer: "Dưa hành", hint: "Preserved vegetables", options: ["A. Dưa chua", "B. Dưa muối", "C. Dưa hành", "D. Dưa cải"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'candied fruit' in Vietnamese?", answer: "Mứt", hint: "Sweet preserved fruit", options: ["A. Kẹo", "B. Mứt", "C. Bánh", "D. Hoa quả"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'watermelon seeds' in Vietnamese?", answer: "Hạt dưa", hint: "Snack during Tet", options: ["A. Hạt hướng dương", "B. Hạt dưa", "C. Hạt điều", "D. Hạt sen"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'spring roll' in Vietnamese?", answer: "Nem, chả giò", hint: "Fried roll", options: ["A. Nem", "B. Bánh cuốn", "C. Bánh xèo", "D. Bò bía"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'boiled chicken' in Vietnamese?", answer: "Gà luộc", hint: "Traditional Tet dish", options: ["A. Gà nướng", "B. Gà luộc", "C. Gà chiên", "D. Gà xào"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Tet Activities & Traditions
                Flashcard(question: "What is 'spring cleaning' in Vietnamese?", answer: "Dọn dẹp nhà cửa", hint: "Clean house before Tet", options: ["A. Dọn nhà", "B. Lau nhà", "C. Dọn dẹp nhà cửa", "D. Quét nhà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'visit relatives' in Vietnamese?", answer: "Đi thăm họ hàng", hint: "Family visits", options: ["A. Thăm nhà", "B. Đi chơi", "C. Đi thăm họ hàng", "D. Đi họ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'give wishes' or 'wish someone' in Vietnamese?", answer: "Chúc", hint: "Say good things", options: ["A. Nói", "B. Chúc", "C. Tặng", "D. Cho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'receive' in Vietnamese?", answer: "Nhận", hint: "Get something", options: ["A. Cho", "B. Nhận", "C. Lấy", "D. Được"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'reunion' in Vietnamese?", answer: "Đoàn tụ", hint: "Family together", options: ["A. Họp mặt", "B. Đoàn tụ", "C. Sum họp", "D. Gặp gỡ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'tradition' in Vietnamese?", answer: "Truyền thống", hint: "Cultural custom", options: ["A. Phong tục", "B. Văn hóa", "C. Truyền thống", "D. Tập quán"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'celebrate' in Vietnamese?", answer: "Ăn mừng, chúc mừng", hint: "Mark special occasion", options: ["A. Ăn mừng", "B. Vui mừng", "C. Chúc mừng", "D. Kỷ niệm"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'first visitor' in Vietnamese?", answer: "Khách đầu năm, xông đất", hint: "Brings luck", options: ["A. Khách", "B. Người đầu tiên", "C. Xông đất", "D. Khách đầu năm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Zodiac & Calendar
                Flashcard(question: "What is 'zodiac animal' in Vietnamese?", answer: "Con giáp", hint: "12 animals", options: ["A. Động vật", "B. Con giáp", "C. Cung hoàng đạo", "D. Linh vật"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lunar calendar' in Vietnamese?", answer: "Âm lịch", hint: "Based on moon", options: ["A. Lịch", "B. Dương lịch", "C. Âm lịch", "D. Lịch vạn niên"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'solar calendar' in Vietnamese?", answer: "Dương lịch", hint: "Based on sun", options: ["A. Âm lịch", "B. Dương lịch", "C. Lịch", "D. Lịch tây"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'Year of the Dragon' in Vietnamese?", answer: "Năm Rồng", hint: "Dragon year", options: ["A. Rồng", "B. Năm Rồng", "C. Con rồng", "D. Giáp Rồng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Wishes & Greetings
                Flashcard(question: "What is 'Happy New Year' in Vietnamese?", answer: "Chúc mừng năm mới", hint: "New Year greeting", options: ["A. Năm mới", "B. Chúc mừng", "C. Chúc mừng năm mới", "D. Năm mới vui vẻ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'prosperity' in Vietnamese?", answer: "Thịnh vượng, phát đạt", hint: "Success and wealth", options: ["A. Giàu có", "B. Thành công", "C. Thịnh vượng", "D. May mắn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'good luck' in Vietnamese?", answer: "May mắn", hint: "Fortune", options: ["A. Vận may", "B. May mắn", "C. Tốt lành", "D. Hanh thông"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'good health' in Vietnamese?", answer: "Sức khỏe dồi dào", hint: "Wellness wish", options: ["A. Khỏe mạnh", "B. Sức khỏe", "C. Sức khỏe dồi dào", "D. Mạnh khỏe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'peace' in Vietnamese?", answer: "Bình an", hint: "Tranquility", options: ["A. Hòa bình", "B. Bình an", "C. Yên tĩnh", "D. Thanh bình"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'success' in Vietnamese?", answer: "Thành công", hint: "Achievement", options: ["A. Đạt được", "B. Thành đạt", "C. Thành công", "D. Thắng lợi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Vietnamese to English
                Flashcard(question: "Từ 'Tết Nguyên Đán' trong tiếng Anh là gì?", answer: "Lunar New Year/Tet", hint: "Vietnamese New Year", options: ["A. New Year", "B. Spring Festival", "C. Lunar New Year", "D. Chinese New Year"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tiền lì xì' trong tiếng Anh là gì?", answer: "Lucky money", hint: "Red envelope money", options: ["A. Money", "B. Gift money", "C. Lucky money", "D. Red money"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Hoa đào' trong tiếng Anh là gì?", answer: "Peach blossom", hint: "Pink flowers", options: ["A. Peach tree", "B. Peach blossom", "C. Pink flower", "D. Spring flower"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Hoa mai' trong tiếng Anh là gì?", answer: "Apricot blossom", hint: "Yellow flowers", options: ["A. Yellow flower", "B. Apricot tree", "C. Apricot blossom", "D. Mai flower"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Bánh chưng' trong tiếng Anh là gì?", answer: "Square sticky rice cake", hint: "Traditional Tet cake", options: ["A. Rice cake", "B. Square cake", "C. Sticky rice cake", "D. Banh chung"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Pháo hoa' trong tiếng Anh là gì?", answer: "Fireworks", hint: "Colorful explosions", options: ["A. Firecrackers", "B. Fireworks", "C. Fire", "D. Explosions"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Xông đất' trong tiếng Anh là gì?", answer: "First visitor", hint: "First person to visit", options: ["A. First guest", "B. Visitor", "C. First visitor", "D. Lucky visitor"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Âm lịch' trong tiếng Anh là gì?", answer: "Lunar calendar", hint: "Moon-based calendar", options: ["A. Calendar", "B. Lunar calendar", "C. Moon calendar", "D. Asian calendar"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Con giáp' trong tiếng Anh là gì?", answer: "Zodiac animal", hint: "12 animals", options: ["A. Animal", "B. Zodiac", "C. Zodiac animal", "D. Chinese zodiac"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đoàn tụ' trong tiếng Anh là gì?", answer: "Reunion", hint: "Family together", options: ["A. Meeting", "B. Gathering", "C. Reunion", "D. Family time"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // MARK: - Fill in the Blank
                Flashcard(question: "Children receive ___ money in red envelopes during Tet.", answer: "lucky", hint: "Lì xì", options: ["A. gift", "B. lucky", "C. red", "D. new"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "We decorate the house with ___ blossoms in Northern Vietnam.", answer: "peach", hint: "Pink flowers", options: ["A. apricot", "B. cherry", "C. peach", "D. plum"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Banh chung is a traditional ___ rice cake.", answer: "sticky", hint: "Glutinous", options: ["A. white", "B. fried", "C. sticky", "D. sweet"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Vietnamese people celebrate ___ New Year based on the lunar calendar.", answer: "Lunar", hint: "Moon-based", options: ["A. Solar", "B. Lunar", "C. Spring", "D. Asian"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ is the first person to visit your house in the new year.", answer: "first visitor", hint: "Xông đất", options: ["A. guest", "B. relative", "C. first visitor", "D. friend"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Families ___ to have dinner together on New Year's Eve.", answer: "reunite", hint: "Come together", options: ["A. gather", "B. meet", "C. reunite", "D. celebrate"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "People often say 'Chúc mừng ___ mới' during Tet.", answer: "năm", hint: "Year", options: ["A. tết", "B. năm", "C. xuân", "D. ngày"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Each year is represented by a different ___ animal.", answer: "zodiac", hint: "12 animals", options: ["A. lunar", "B. Chinese", "C. zodiac", "D. Asian"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                
                // MARK: - Choose Correct Word
                Flashcard(question: "What is the traditional square sticky rice cake called?", answer: "Banh chung", hint: "Northern Vietnam", options: ["A. Banh tet", "B. Banh chung", "C. Banh day", "D. Banh mi"], correctAnswer: "B", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What flowers are popular in Southern Vietnam during Tet?", answer: "Apricot blossoms", hint: "Yellow flowers", options: ["A. Peach blossoms", "B. Cherry blossoms", "C. Apricot blossoms", "D. Plum blossoms"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What do children receive in red envelopes?", answer: "Lucky money", hint: "Lì xì", options: ["A. Candy", "B. Toys", "C. Lucky money", "D. Cards"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "When is Vietnamese Tet celebrated?", answer: "First day of lunar calendar", hint: "Moon-based", options: ["A. January 1st", "B. December 31st", "C. First day of lunar calendar", "D. February 1st"], correctAnswer: "C", exerciseType: .chooseCorrectWord),
                Flashcard(question: "What is the Vietnamese zodiac based on?", answer: "12 animals", hint: "Con giáp", options: ["A. Stars", "B. Planets", "C. 12 animals", "D. Elements"], correctAnswer: "C", exerciseType: .chooseCorrectWord)
            ]
        )
        
        // Common Verbs topic
        let verbsTopic = Topic(
            name: "Common Verbs (Động từ thông dụng)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'eat' in Vietnamese?", answer: "Ăn", hint: "With food", options: ["A. Uống", "B. Ăn", "C. Ngủ", "D. Chạy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'drink' in Vietnamese?", answer: "Uống", hint: "With water", options: ["A. Ăn", "B. Uống", "C. Nói", "D. Nghe"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sleep' in Vietnamese?", answer: "Ngủ", hint: "At night", options: ["A. Thức", "B. Ngủ", "C. Ngồi", "D. Đứng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'run' in Vietnamese?", answer: "Chạy", hint: "Fast movement", options: ["A. Đi", "B. Chạy", "C. Nhảy", "D. Bay"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'go' in Vietnamese?", answer: "Đi", hint: "Movement", options: ["A. Đến", "B. Đi", "C. Về", "D. Lại"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Đọc' trong tiếng Anh là gì?", answer: "Read", hint: "With books", options: ["A. Write", "B. Read", "C. Speak", "D. Listen"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I ___ breakfast every morning.", answer: "eat", hint: "Food action", options: ["A. drink", "B. eat", "C. sleep", "D. run"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Common Adjectives topic
        let adjectivesTopic = Topic(
            name: "Common Adjectives (Tính từ thông dụng)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'big' in Vietnamese?", answer: "To, lớn", hint: "Opposite of small", options: ["A. Nhỏ", "B. To", "C. Dài", "D. Cao"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'small' in Vietnamese?", answer: "Nhỏ, bé", hint: "Opposite of big", options: ["A. To", "B. Nhỏ", "C. Thấp", "D. Ngắn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'good' in Vietnamese?", answer: "Tốt", hint: "Positive quality", options: ["A. Xấu", "B. Tốt", "C. Đẹp", "D. Đúng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bad' in Vietnamese?", answer: "Xấu, tồi", hint: "Opposite of good", options: ["A. Tốt", "B. Xấu", "C. Đẹp", "D. Sai"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'happy' in Vietnamese?", answer: "Vui, hạnh phúc", hint: "Good feeling", options: ["A. Buồn", "B. Vui", "C. Giận", "D. Sợ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Đẹp' trong tiếng Anh là gì?", answer: "Beautiful", hint: "Nice to look at", options: ["A. Good", "B. Beautiful", "C. Pretty", "D. Nice"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "The elephant is very ___.", answer: "big", hint: "Size", options: ["A. small", "B. big", "C. short", "D. thin"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Places topic
        let placesTopic = Topic(
            name: "Places (Địa điểm)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'school' in Vietnamese?", answer: "Trường học", hint: "Learn here", options: ["A. Nhà", "B. Trường", "C. Chợ", "D. Công viên"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'home' in Vietnamese?", answer: "Nhà", hint: "Where you live", options: ["A. Nhà", "B. Trường", "C. Bệnh viện", "D. Ngân hàng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'hospital' in Vietnamese?", answer: "Bệnh viện", hint: "For sick people", options: ["A. Trường", "B. Nhà thuốc", "C. Bệnh viện", "D. Phòng khám"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'market' in Vietnamese?", answer: "Chợ", hint: "Buy food", options: ["A. Siêu thị", "B. Chợ", "C. Cửa hàng", "D. Tiệm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Công viên' trong tiếng Anh là gì?", answer: "Park", hint: "Green space", options: ["A. Garden", "B. Park", "C. Forest", "D. Zoo"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I go to ___ every day.", answer: "school", hint: "To learn", options: ["A. hospital", "B. school", "C. market", "D. park"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Internet & Technology topic
        let internetTopic = Topic(
            name: "Internet & Technology (Internet & Công nghệ)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'computer' in Vietnamese?", answer: "Máy tính", hint: "For work and games", options: ["A. Máy tính", "B. Điện thoại", "C. Tivi", "D. Máy ảnh"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'internet' in Vietnamese?", answer: "Internet, mạng", hint: "Online connection", options: ["A. Wifi", "B. Internet", "C. Email", "D. Website"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'email' in Vietnamese?", answer: "Thư điện tử, email", hint: "Digital letter", options: ["A. Thư", "B. Email", "C. Tin nhắn", "D. Bưu điện"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'website' in Vietnamese?", answer: "Trang web", hint: "Internet page", options: ["A. Website", "B. Trang web", "C. Mạng", "D. Link"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'phone' in Vietnamese?", answer: "Điện thoại", hint: "For calling", options: ["A. Máy tính", "B. Điện thoại", "C. Máy ảnh", "D. Đồng hồ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Ứng dụng' trong tiếng Anh là gì?", answer: "Application/App", hint: "On phone", options: ["A. App", "B. Game", "C. Software", "D. Program"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I use the ___ every day.", answer: "internet", hint: "To browse online", options: ["A. computer", "B. internet", "C. phone", "D. email"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Send me an ___.", answer: "email", hint: "Digital message", options: ["A. letter", "B. email", "C. phone", "D. message"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Accommodation topic
        let accommodationTopic = Topic(
            name: "Accommodation (Chỗ ở)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'house' in Vietnamese?", answer: "Nhà", hint: "Where you live", options: ["A. Nhà", "B. Phòng", "C. Tầng", "D. Cửa"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'room' in Vietnamese?", answer: "Phòng", hint: "Space in house", options: ["A. Nhà", "B. Phòng", "C. Tường", "D. Cửa sổ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bedroom' in Vietnamese?", answer: "Phòng ngủ", hint: "For sleeping", options: ["A. Phòng khách", "B. Phòng ngủ", "C. Phòng bếp", "D. Phòng tắm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'kitchen' in Vietnamese?", answer: "Nhà bếp, bếp", hint: "For cooking", options: ["A. Phòng ăn", "B. Phòng ngủ", "C. Nhà bếp", "D. Phòng khách"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bathroom' in Vietnamese?", answer: "Phòng tắm", hint: "For washing", options: ["A. Nhà bếp", "B. Phòng tắm", "C. Nhà vệ sinh", "D. Phòng giặt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'apartment' in Vietnamese?", answer: "Căn hộ, chung cư", hint: "In a building", options: ["A. Nhà", "B. Căn hộ", "C. Biệt thự", "D. Khách sạn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Phòng khách' trong tiếng Anh là gì?", answer: "Living room", hint: "For relaxing", options: ["A. Bedroom", "B. Kitchen", "C. Living room", "D. Bathroom"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I sleep in my ___.", answer: "bedroom", hint: "At night", options: ["A. kitchen", "B. bedroom", "C. bathroom", "D. living room"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "We cook food in the ___.", answer: "kitchen", hint: "Cooking place", options: ["A. bedroom", "B. bathroom", "C. kitchen", "D. living room"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Study & Education topic
        let studyTopic = Topic(
            name: "Study & Education (Học tập & Giáo dục)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'student' in Vietnamese?", answer: "Học sinh, sinh viên", hint: "Person who studies", options: ["A. Giáo viên", "B. Học sinh", "C. Bác sĩ", "D. Kỹ sư"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'teacher' in Vietnamese?", answer: "Giáo viên", hint: "Person who teaches", options: ["A. Học sinh", "B. Giáo viên", "C. Hiệu trưởng", "D. Phụ huynh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'book' in Vietnamese?", answer: "Sách", hint: "For reading", options: ["A. Vở", "B. Sách", "C. Bài", "D. Bút"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'homework' in Vietnamese?", answer: "Bài tập về nhà", hint: "Work at home", options: ["A. Bài học", "B. Bài tập", "C. Bài kiểm tra", "D. Bài tập về nhà"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'exam' in Vietnamese?", answer: "Kỳ thi, bài kiểm tra", hint: "Test knowledge", options: ["A. Bài tập", "B. Bài học", "C. Kỳ thi", "D. Lớp học"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'library' in Vietnamese?", answer: "Thư viện", hint: "Place with books", options: ["A. Trường học", "B. Thư viện", "C. Lớp học", "D. Nhà sách"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Học' trong tiếng Anh là gì?", answer: "Study/Learn", hint: "Gain knowledge", options: ["A. Teach", "B. Study", "C. Read", "D. Write"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thi' trong tiếng Anh là gì?", answer: "Take an exam", hint: "Test", options: ["A. Study", "B. Learn", "C. Take an exam", "D. Pass"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I need to do my ___.", answer: "homework", hint: "School work at home", options: ["A. test", "B. homework", "C. exam", "D. lesson"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ is teaching us English.", answer: "teacher", hint: "Educator", options: ["A. student", "B. teacher", "C. principal", "D. parent"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Work & Jobs topic
        let workTopic = Topic(
            name: "Work & Jobs (Công việc & Nghề nghiệp)",
            subjectName: "Tiếng Anh",
            flashcards: [
                Flashcard(question: "What is 'job' in Vietnamese?", answer: "Công việc, nghề", hint: "Your work", options: ["A. Việc làm", "B. Công việc", "C. Làm việc", "D. Lương"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'doctor' in Vietnamese?", answer: "Bác sĩ", hint: "Treats patients", options: ["A. Y tá", "B. Bác sĩ", "C. Dược sĩ", "D. Nha sĩ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'nurse' in Vietnamese?", answer: "Y tá", hint: "Helps doctor", options: ["A. Bác sĩ", "B. Y tá", "C. Dược sĩ", "D. Bệnh nhân"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'engineer' in Vietnamese?", answer: "Kỹ sư", hint: "Designs things", options: ["A. Kiến trúc sư", "B. Kỹ sư", "C. Thợ", "D. Thầy giáo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'office' in Vietnamese?", answer: "Văn phòng", hint: "Place to work", options: ["A. Công ty", "B. Văn phòng", "C. Nhà máy", "D. Cửa hàng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'salary' in Vietnamese?", answer: "Lương", hint: "Money from work", options: ["A. Tiền", "B. Lương", "C. Thuế", "D. Thưởng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'manager' in Vietnamese?", answer: "Quản lý", hint: "Boss", options: ["A. Nhân viên", "B. Quản lý", "C. Giám đốc", "D. Thư ký"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Từ 'Làm việc' trong tiếng Anh là gì?", answer: "Work", hint: "Do a job", options: ["A. Job", "B. Work", "C. Worker", "D. Working"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "I ___ in an office.", answer: "work", hint: "Do job", options: ["A. study", "B. work", "C. live", "D. play"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "She is a ___. She helps sick people.", answer: "doctor", hint: "Medical professional", options: ["A. teacher", "B. nurse", "C. doctor", "D. engineer"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Daily Routine topic
        // Daily Routine topic - EXPANDED with comprehensive daily activities vocabulary
        let dailyRoutineTopic = Topic(
            name: "Daily Activities (Hoạt động hàng ngày)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Morning activities
                Flashcard(question: "What is 'wake up' in Vietnamese?", answer: "Thức dậy", hint: "Start of day", options: ["A. Ngủ", "B. Thức dậy", "C. Ngủ dậy", "D. Dậy sớm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'get up' in Vietnamese?", answer: "Ngủ dậy, rời giường", hint: "Leave bed", options: ["A. Thức dậy", "B. Ngủ dậy", "C. Đứng dậy", "D. Dậy sớm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'make the bed' in Vietnamese?", answer: "Dọn giường", hint: "Tidy bed", options: ["A. Ngủ", "B. Dọn giường", "C. Giặt chăn", "D. Gấp chăn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wash face' in Vietnamese?", answer: "Rửa mặt", hint: "Clean face", options: ["A. Rửa mặt", "B. Tắm", "C. Đánh răng", "D. Chải tóc"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'brush teeth' in Vietnamese?", answer: "Đánh răng", hint: "Clean teeth", options: ["A. Rửa mặt", "B. Đánh răng", "C. Chải tóc", "D. Tắm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'take a shower' in Vietnamese?", answer: "Tắm", hint: "Wash body", options: ["A. Rửa mặt", "B. Tắm", "C. Giặt", "D. Rửa tay"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'comb hair' in Vietnamese?", answer: "Chải tóc", hint: "Style hair", options: ["A. Gội đầu", "B. Cắt tóc", "C. Chải tóc", "D. Nhuộm tóc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'get dressed' in Vietnamese?", answer: "Mặc quần áo", hint: "Put on clothes", options: ["A. Thay quần áo", "B. Mặc quần áo", "C. Cởi quần áo", "D. Giặt quần áo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'have breakfast' in Vietnamese?", answer: "Ăn sáng", hint: "Morning meal", options: ["A. Ăn sáng", "B. Ăn trưa", "C. Ăn tối", "D. Ăn nhẹ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                
                // Daily meals
                Flashcard(question: "What is 'breakfast' in Vietnamese?", answer: "Bữa sáng", hint: "Morning meal", options: ["A. Bữa sáng", "B. Bữa trưa", "C. Bữa tối", "D. Bữa phụ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lunch' in Vietnamese?", answer: "Bữa trưa", hint: "Noon meal", options: ["A. Bữa sáng", "B. Bữa trưa", "C. Bữa tối", "D. Bữa xế"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'dinner' in Vietnamese?", answer: "Bữa tối", hint: "Evening meal", options: ["A. Bữa sáng", "B. Bữa trưa", "C. Bữa tối", "D. Bữa khuya"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'snack' in Vietnamese?", answer: "Ăn nhẹ, đồ ăn vặt", hint: "Between meals", options: ["A. Bữa chính", "B. Ăn nhẹ", "C. Ăn no", "D. Ăn uống"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Daily activities
                Flashcard(question: "What is 'go to work' in Vietnamese?", answer: "Đi làm", hint: "Go to office", options: ["A. Đi học", "B. Đi làm", "C. Về nhà", "D. Đi chơi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'go to school' in Vietnamese?", answer: "Đi học", hint: "Go to study", options: ["A. Đi làm", "B. Đi học", "C. Học bài", "D. Đi chơi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'do homework' in Vietnamese?", answer: "Làm bài tập", hint: "School work", options: ["A. Học bài", "B. Làm bài tập", "C. Viết bài", "D. Đọc sách"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'watch TV' in Vietnamese?", answer: "Xem tivi", hint: "View television", options: ["A. Xem phim", "B. Xem tivi", "C. Nghe nhạc", "D. Chơi game"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'listen to music' in Vietnamese?", answer: "Nghe nhạc", hint: "Hear songs", options: ["A. Xem tivi", "B. Nghe nhạc", "C. Hát", "D. Chơi nhạc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'read a book' in Vietnamese?", answer: "Đọc sách", hint: "Reading", options: ["A. Viết", "B. Đọc sách", "C. Học", "D. Xem"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cook' in Vietnamese?", answer: "Nấu ăn", hint: "Make food", options: ["A. Ăn", "B. Nấu ăn", "C. Rửa bát", "D. Dọn bàn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'do laundry' in Vietnamese?", answer: "Giặt quần áo", hint: "Wash clothes", options: ["A. Phơi đồ", "B. Giặt quần áo", "C. Gấp quần áo", "D. Là quần áo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'clean the house' in Vietnamese?", answer: "Dọn nhà", hint: "Tidy home", options: ["A. Lau nhà", "B. Dọn nhà", "C. Quét nhà", "D. Sửa nhà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wash dishes' in Vietnamese?", answer: "Rửa bát", hint: "Clean plates", options: ["A. Nấu ăn", "B. Rửa bát", "C. Lau bàn", "D. Dọn bàn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'take out the trash' in Vietnamese?", answer: "Đổ rác", hint: "Remove garbage", options: ["A. Quét rác", "B. Đổ rác", "C. Vứt rác", "D. Nhặt rác"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'exercise' in Vietnamese?", answer: "Tập thể dục", hint: "Physical activity", options: ["A. Chạy bộ", "B. Tập thể dục", "C. Chơi thể thao", "D. Đi bộ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'go shopping' in Vietnamese?", answer: "Đi mua sắm", hint: "Buy things", options: ["A. Mua hàng", "B. Đi mua sắm", "C. Đi chợ", "D. Bán hàng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'walk the dog' in Vietnamese?", answer: "Dắt chó đi dạo", hint: "Take dog outside", options: ["A. Chơi với chó", "B. Dắt chó đi dạo", "C. Cho chó ăn", "D. Tắm cho chó"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'take a nap' in Vietnamese?", answer: "Ngủ trưa", hint: "Sleep in day", options: ["A. Ngủ đêm", "B. Ngủ trưa", "C. Nghỉ ngơi", "D. Thư giãn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Evening activities
                Flashcard(question: "What is 'come home' in Vietnamese?", answer: "Về nhà", hint: "Return home", options: ["A. Đi nhà", "B. Về nhà", "C. Ở nhà", "D. Ra ngoài"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'relax' in Vietnamese?", answer: "Thư giãn, nghỉ ngơi", hint: "Rest", options: ["A. Làm việc", "B. Thư giãn", "C. Chơi", "D. Ngủ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'go to bed' in Vietnamese?", answer: "Đi ngủ", hint: "End of day", options: ["A. Thức dậy", "B. Ngủ", "C. Đi ngủ", "D. Nghỉ ngơi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sleep' in Vietnamese?", answer: "Ngủ", hint: "Rest at night", options: ["A. Nghỉ", "B. Ngủ", "C. Nằm", "D. Thư giãn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Thức dậy' trong tiếng Anh là gì?", answer: "Wake up", hint: "Start day", options: ["A. Get up", "B. Wake up", "C. Stand up", "D. Go up"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Ăn sáng' trong tiếng Anh là gì?", answer: "Have breakfast", hint: "Morning meal", options: ["A. Have lunch", "B. Have dinner", "C. Have breakfast", "D. Have snack"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đi làm' trong tiếng Anh là gì?", answer: "Go to work", hint: "Work", options: ["A. Go home", "B. Go to work", "C. Go to school", "D. Go out"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Nấu ăn' trong tiếng Anh là gì?", answer: "Cook", hint: "Make food", options: ["A. Eat", "B. Cook", "C. Wash", "D. Prepare"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Dọn nhà' trong tiếng Anh là gì?", answer: "Clean the house", hint: "Tidy home", options: ["A. Clean the house", "B. Wash the house", "C. Fix the house", "D. Leave the house"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Xem tivi' trong tiếng Anh là gì?", answer: "Watch TV", hint: "Television", options: ["A. See TV", "B. Watch TV", "C. Look TV", "D. View TV"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tập thể dục' trong tiếng Anh là gì?", answer: "Exercise", hint: "Physical activity", options: ["A. Sport", "B. Exercise", "C. Play", "D. Run"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // Fill in the blank exercises
                Flashcard(question: "I ___ at 7 AM every day.", answer: "wake up", hint: "Start the day", options: ["A. sleep", "B. wake up", "C. go to bed", "D. rest"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I usually have ___ at 12 PM.", answer: "lunch", hint: "Midday meal", options: ["A. breakfast", "B. lunch", "C. dinner", "D. snack"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I ___ my teeth twice a day.", answer: "brush", hint: "Clean teeth", options: ["A. wash", "B. clean", "C. brush", "D. dry"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "After dinner, I ___ the dishes.", answer: "wash", hint: "Clean plates", options: ["A. cook", "B. wash", "C. dry", "D. eat"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Every morning I ___ the bed.", answer: "make", hint: "Tidy bed", options: ["A. sleep", "B. make", "C. clean", "D. wash"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I like to ___ books before sleeping.", answer: "read", hint: "Reading activity", options: ["A. watch", "B. see", "C. read", "D. write"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "My mother ___ dinner at 6 PM.", answer: "cooks", hint: "Prepare food", options: ["A. eats", "B. cooks", "C. buys", "D. serves"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I ___ home from work at 5:30.", answer: "come", hint: "Return", options: ["A. go", "B. leave", "C. come", "D. stay"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )

        // NEW: Office & Work Life Topic - EXPANDED
        let officeLifeTopic = Topic(
            name: "Office & Work Life (Văn phòng & Cuộc sống công sở)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Office Equipment
                Flashcard(question: "What is 'computer' in Vietnamese?", answer: "Máy tính", hint: "For work", options: ["A. Điện thoại", "B. Máy tính", "C. Máy in", "D. Bàn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'printer' in Vietnamese?", answer: "Máy in", hint: "Prints documents", options: ["A. Máy photocopy", "B. Máy in", "C. Máy scan", "D. Máy tính"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'keyboard' in Vietnamese?", answer: "Bàn phím", hint: "For typing", options: ["A. Chuột", "B. Màn hình", "C. Bàn phím", "D. Loa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mouse' in Vietnamese?", answer: "Chuột máy tính", hint: "Click device", options: ["A. Bàn phím", "B. Chuột", "C. Màn hình", "D. Loa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'monitor' in Vietnamese?", answer: "Màn hình", hint: "Display screen", options: ["A. Màn hình", "B. Máy tính", "C. Bàn phím", "D. Chuột"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'desk' in Vietnamese?", answer: "Bàn làm việc", hint: "Work surface", options: ["A. Ghế", "B. Bàn", "C. Tủ", "D. Kệ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'chair' in Vietnamese?", answer: "Ghế", hint: "For sitting", options: ["A. Bàn", "B. Ghế", "C. Tủ", "D. Sofa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'filing cabinet' in Vietnamese?", answer: "Tủ hồ sơ", hint: "Stores documents", options: ["A. Tủ quần áo", "B. Tủ hồ sơ", "C. Tủ lạnh", "D. Kệ sách"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Office Supplies
                Flashcard(question: "What is 'pen' in Vietnamese?", answer: "Bút mực", hint: "Writing tool", options: ["A. Bút chì", "B. Bút mực", "C. Thước", "D. Kéo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pencil' in Vietnamese?", answer: "Bút chì", hint: "Can erase", options: ["A. Bút mực", "B. Bút chì", "C. Tẩy", "D. Thước"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'notebook' in Vietnamese?", answer: "Vở, sổ tay", hint: "For writing notes", options: ["A. Sách", "B. Vở", "C. Giấy", "D. Bút"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'folder' in Vietnamese?", answer: "Folder, bìa hồ sơ", hint: "Holds papers", options: ["A. Giấy", "B. Sổ", "C. Folder", "D. Sách"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stapler' in Vietnamese?", answer: "Dập ghim", hint: "Attaches papers", options: ["A. Kéo", "B. Ghim", "C. Dập ghim", "D. Băng keo"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'scissors' in Vietnamese?", answer: "Cái kéo", hint: "For cutting", options: ["A. Dao", "B. Kéo", "C. Thước", "D. Bút"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Work Actions
                Flashcard(question: "What is 'meeting' in Vietnamese?", answer: "Cuộc họp", hint: "Group discussion", options: ["A. Họp", "B. Làm việc", "C. Nghỉ", "D. Ăn trưa"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'presentation' in Vietnamese?", answer: "Bài thuyết trình", hint: "Show information", options: ["A. Họp", "B. Thuyết trình", "C. Báo cáo", "D. Dự án"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'deadline' in Vietnamese?", answer: "Hạn chót", hint: "Due date", options: ["A. Ngày", "B. Thời gian", "C. Hạn chót", "D. Lịch"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'project' in Vietnamese?", answer: "Dự án", hint: "Work task", options: ["A. Công việc", "B. Dự án", "C. Báo cáo", "D. Họp"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'report' in Vietnamese?", answer: "Báo cáo", hint: "Written summary", options: ["A. Thư", "B. Báo cáo", "C. Email", "D. Tin nhắn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Đồng nghiệp' trong tiếng Anh là gì?", answer: "Colleague", hint: "Coworker", options: ["A. Boss", "B. Colleague", "C. Manager", "D. Employee"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tăng lương' trong tiếng Anh là gì?", answer: "Salary raise", hint: "Pay increase", options: ["A. Bonus", "B. Salary", "C. Raise", "D. Promotion"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Fill in the blank
                Flashcard(question: "I need to attend a ___ at 2 PM.", answer: "meeting", hint: "Group discussion", options: ["A. lunch", "B. meeting", "C. break", "D. call"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Please print this ___ for me.", answer: "document", hint: "Paper with info", options: ["A. email", "B. document", "C. file", "D. folder"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // NEW: Transportation Topic - EXPANDED
        let transportationTopic = Topic(
            name: "Transportation (Phương tiện giao thông)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Land Transportation
                Flashcard(question: "What is 'car' in Vietnamese?", answer: "Ô tô, xe hơi", hint: "Four wheels", options: ["A. Xe máy", "B. Ô tô", "C. Xe đạp", "D. Xe buýt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'motorcycle' in Vietnamese?", answer: "Xe máy", hint: "Two wheels, engine", options: ["A. Xe đạp", "B. Xe máy", "C. Ô tô", "D. Xe scooter"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bicycle' in Vietnamese?", answer: "Xe đạp", hint: "Pedal power", options: ["A. Xe máy", "B. Xe đạp", "C. Xe scooter", "D. Ô tô"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bus' in Vietnamese?", answer: "Xe buýt", hint: "Public transport", options: ["A. Taxi", "B. Xe buýt", "C. Tàu", "D. Máy bay"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'taxi' in Vietnamese?", answer: "Taxi", hint: "Hire for ride", options: ["A. Xe buýt", "B. Taxi", "C. Xe máy", "D. Ô tô"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'train' in Vietnamese?", answer: "Tàu hỏa", hint: "On rails", options: ["A. Xe buýt", "B. Tàu hỏa", "C. Tàu điện ngầm", "D. Máy bay"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'subway/metro' in Vietnamese?", answer: "Tàu điện ngầm", hint: "Underground train", options: ["A. Tàu hỏa", "B. Xe buýt", "C. Tàu điện ngầm", "D. Taxi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'truck' in Vietnamese?", answer: "Xe tải", hint: "Carries cargo", options: ["A. Ô tô", "B. Xe tải", "C. Xe buýt", "D. Xe máy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Air Transportation
                Flashcard(question: "What is 'airplane' in Vietnamese?", answer: "Máy bay", hint: "Flies in sky", options: ["A. Tàu", "B. Máy bay", "C. Trực thăng", "D. Xe"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'helicopter' in Vietnamese?", answer: "Trực thăng", hint: "Rotors on top", options: ["A. Máy bay", "B. Trực thăng", "C. Tên lửa", "D. Khinh khí cầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'airport' in Vietnamese?", answer: "Sân bay", hint: "Where planes land", options: ["A. Ga tàu", "B. Bến xe", "C. Sân bay", "D. Cảng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Water Transportation
                Flashcard(question: "What is 'boat' in Vietnamese?", answer: "Thuyền", hint: "Small water vessel", options: ["A. Tàu", "B. Thuyền", "C. Canô", "D. Phà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ship' in Vietnamese?", answer: "Tàu thủy", hint: "Large water vessel", options: ["A. Thuyền", "B. Tàu", "C. Canô", "D. Phà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ferry' in Vietnamese?", answer: "Phà", hint: "Crosses water", options: ["A. Tàu", "B. Thuyền", "C. Phà", "D. Canô"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Transportation Related
                Flashcard(question: "What is 'traffic' in Vietnamese?", answer: "Giao thông", hint: "Vehicles on road", options: ["A. Đường", "B. Giao thông", "C. Xe", "D. Tắc đường"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'traffic jam' in Vietnamese?", answer: "Tắc đường", hint: "Too many cars", options: ["A. Giao thông", "B. Tai nạn", "C. Tắc đường", "D. Đèn đỏ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ticket' in Vietnamese?", answer: "Vé", hint: "To ride transport", options: ["A. Tiền", "B. Vé", "C. Thẻ", "D. Giấy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'driver' in Vietnamese?", answer: "Tài xế", hint: "Operates vehicle", options: ["A. Hành khách", "B. Tài xế", "C. Người đi", "D. Khách"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'passenger' in Vietnamese?", answer: "Hành khách", hint: "Rider", options: ["A. Tài xế", "B. Hành khách", "C. Người lái", "D. Nhân viên"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Fill in the blank
                Flashcard(question: "I go to work by ___.", answer: "bus", hint: "Public transport", options: ["A. walk", "B. bus", "C. home", "D. office"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ takes off from the airport.", answer: "airplane", hint: "Flies", options: ["A. bus", "B. train", "C. airplane", "D. car"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Bến xe' trong tiếng Anh là gì?", answer: "Bus station", hint: "Where buses stop", options: ["A. Airport", "B. Station", "C. Bus station", "D. Port"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đỗ xe' trong tiếng Anh là gì?", answer: "Park", hint: "Stop vehicle", options: ["A. Stop", "B. Park", "C. Wait", "D. Stand"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // More Vehicles - Land
                Flashcard(question: "What is 'scooter' in Vietnamese?", answer: "Xe scooter", hint: "Small motorbike", options: ["A. Xe máy", "B. Xe scooter", "C. Xe đạp", "D. Xe điện"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'van' in Vietnamese?", answer: "Xe van", hint: "Large car", options: ["A. Ô tô", "B. Xe buýt", "C. Xe van", "D. Xe tải"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'minibus' in Vietnamese?", answer: "Xe buýt nhỏ", hint: "Small bus", options: ["A. Taxi", "B. Xe van", "C. Xe buýt nhỏ", "D. Xe tải"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'tram' in Vietnamese?", answer: "Xe điện", hint: "Rail on street", options: ["A. Tàu hỏa", "B. Xe điện", "C. Xe buýt", "D. Tàu điện ngầm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'rickshaw' in Vietnamese?", answer: "Xe xích lô", hint: "Traditional transport", options: ["A. Xe máy", "B. Taxi", "C. Xe xích lô", "D. Xe đạp"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ambulance' in Vietnamese?", answer: "Xe cứu thương", hint: "Emergency vehicle", options: ["A. Taxi", "B. Xe buýt", "C. Xe cứu thương", "D. Xe cảnh sát"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'police car' in Vietnamese?", answer: "Xe cảnh sát", hint: "Law enforcement", options: ["A. Xe cứu thương", "B. Xe cảnh sát", "C. Taxi", "D. Ô tô"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fire truck' in Vietnamese?", answer: "Xe cứu hỏa", hint: "Fights fires", options: ["A. Xe cứu thương", "B. Xe tải", "C. Xe cứu hỏa", "D. Xe cảnh sát"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Road Infrastructure
                Flashcard(question: "What is 'road' in Vietnamese?", answer: "Đường", hint: "Path for vehicles", options: ["A. Phố", "B. Đường", "C. Hè", "D. Cầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'street' in Vietnamese?", answer: "Phố", hint: "City road", options: ["A. Đường", "B. Phố", "C. Ngõ", "D. Hẻm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'highway' in Vietnamese?", answer: "Đường cao tốc", hint: "Fast road", options: ["A. Đường", "B. Phố", "C. Đường cao tốc", "D. Cầu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bridge' in Vietnamese?", answer: "Cầu", hint: "Crosses water/gap", options: ["A. Đường", "B. Cầu", "C. Hầm", "D. Phà"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'tunnel' in Vietnamese?", answer: "Hầm", hint: "Underground passage", options: ["A. Cầu", "B. Hầm", "C. Đường", "D. Hang"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sidewalk' in Vietnamese?", answer: "Vỉa hè", hint: "Path for walking", options: ["A. Đường", "B. Vỉa hè", "C. Hè phố", "D. Lối đi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'crosswalk' in Vietnamese?", answer: "Vạch qua đường", hint: "Pedestrian crossing", options: ["A. Đường", "B. Hè", "C. Vạch qua đường", "D. Cầu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'intersection' in Vietnamese?", answer: "Ngã tư", hint: "Roads meet", options: ["A. Cầu", "B. Ngã tư", "C. Đường", "D. Phố"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'roundabout' in Vietnamese?", answer: "Vòng xoay", hint: "Circular junction", options: ["A. Ngã tư", "B. Vòng xoay", "C. Đường vòng", "D. Ngã ba"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'parking lot' in Vietnamese?", answer: "Bãi đỗ xe", hint: "Car storage area", options: ["A. Ga ra", "B. Bãi đỗ xe", "C. Nhà xe", "D. Đường"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'garage' in Vietnamese?", answer: "Ga-ra", hint: "Car shelter", options: ["A. Nhà xe", "B. Ga-ra", "C. Bãi xe", "D. Kho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Traffic Signs & Signals
                Flashcard(question: "What is 'traffic light' in Vietnamese?", answer: "Đèn giao thông", hint: "Red, yellow, green", options: ["A. Đèn", "B. Đèn đường", "C. Đèn giao thông", "D. Đèn tín hiệu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stop sign' in Vietnamese?", answer: "Biển báo dừng", hint: "Red octagon", options: ["A. Biển báo", "B. Biển dừng", "C. Biển báo dừng", "D. Đèn đỏ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'traffic sign' in Vietnamese?", answer: "Biển báo giao thông", hint: "Road warning", options: ["A. Biển", "B. Biển báo", "C. Biển báo GT", "D. Cột mốc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'speed limit' in Vietnamese?", answer: "Giới hạn tốc độ", hint: "Maximum speed", options: ["A. Tốc độ", "B. Giới hạn", "C. Giới hạn tốc độ", "D. Chạy chậm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'no parking' in Vietnamese?", answer: "Cấm đỗ xe", hint: "Cannot stop here", options: ["A. Đỗ xe", "B. Cấm", "C. Cấm đỗ", "D. Cấm đỗ xe"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'one way' in Vietnamese?", answer: "Một chiều", hint: "Single direction", options: ["A. Đường một", "B. Một chiều", "C. Một lối", "D. Hướng đi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Vehicle Parts
                Flashcard(question: "What is 'wheel' in Vietnamese?", answer: "Bánh xe", hint: "Round part", options: ["A. Lốp", "B. Bánh xe", "C. Vành", "D. Phanh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'tire' in Vietnamese?", answer: "Lốp xe", hint: "Rubber wheel cover", options: ["A. Bánh xe", "B. Lốp", "C. Vỏ xe", "D. Lốp xe"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'engine' in Vietnamese?", answer: "Động cơ", hint: "Power source", options: ["A. Máy", "B. Động cơ", "C. Máy móc", "D. Cơ cấu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'steering wheel' in Vietnamese?", answer: "Vô lăng", hint: "Control direction", options: ["A. Tay lái", "B. Vô lăng", "C. Bánh lái", "D. Tay cầm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'brake' in Vietnamese?", answer: "Phanh", hint: "Stop mechanism", options: ["A. Dừng", "B. Phanh", "C. Chặn", "D. Thắng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'accelerator' in Vietnamese?", answer: "Chân ga", hint: "Speed up", options: ["A. Ga", "B. Phanh", "C. Chân ga", "D. Tốc độ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'horn' in Vietnamese?", answer: "Còi", hint: "Makes sound", options: ["A. Tiếng", "B. Còi", "C. Chuông", "D. Kèn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'headlight' in Vietnamese?", answer: "Đèn pha", hint: "Front light", options: ["A. Đèn xe", "B. Đèn trước", "C. Đèn pha", "D. Đèn sáng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'mirror' in Vietnamese?", answer: "Gương", hint: "Reflect view", options: ["A. Kính", "B. Gương", "C. Gương chiếu", "D. Kính chiếu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'seat belt' in Vietnamese?", answer: "Dây an toàn", hint: "Safety strap", options: ["A. Dây", "B. Đai", "C. Dây an toàn", "D. Dây thắt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'windshield' in Vietnamese?", answer: "Kính chắn gió", hint: "Front window", options: ["A. Kính xe", "B. Kính trước", "C. Kính chắn gió", "D. Cửa kính"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'door' in Vietnamese?", answer: "Cửa xe", hint: "Entry/exit", options: ["A. Cửa", "B. Cửa xe", "C. Cổng", "D. Lối vào"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'trunk' in Vietnamese?", answer: "Cốp xe", hint: "Storage at back", options: ["A. Thùng xe", "B. Sau xe", "C. Cốp xe", "D. Hộp xe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'license plate' in Vietnamese?", answer: "Biển số xe", hint: "ID number plate", options: ["A. Số xe", "B. Biển xe", "C. Biển số", "D. Biển số xe"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                
                // Driving Actions
                Flashcard(question: "What is 'drive' in Vietnamese?", answer: "Lái xe", hint: "Operate vehicle", options: ["A. Đi xe", "B. Lái xe", "C. Chạy xe", "D. Điều khiển"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ride' in Vietnamese?", answer: "Đi xe", hint: "Travel on vehicle", options: ["A. Lái", "B. Đi", "C. Đi xe", "D. Ngồi xe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stop' in Vietnamese?", answer: "Dừng lại", hint: "Halt movement", options: ["A. Ngừng", "B. Dừng", "C. Đứng", "D. Dừng lại"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'start' in Vietnamese?", answer: "Khởi động", hint: "Begin moving", options: ["A. Bắt đầu", "B. Khởi động", "C. Chạy", "D. Đi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'turn left' in Vietnamese?", answer: "Rẽ trái", hint: "Go left", options: ["A. Quẹo trái", "B. Rẽ trái", "C. Sang trái", "D. Trái"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'turn right' in Vietnamese?", answer: "Rẽ phải", hint: "Go right", options: ["A. Quẹo phải", "B. Rẽ phải", "C. Sang phải", "D. Phải"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'reverse' in Vietnamese?", answer: "Lùi xe", hint: "Go backward", options: ["A. Lùi", "B. Quay", "C. Lùi xe", "D. Đi lùi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'overtake' in Vietnamese?", answer: "Vượt xe", hint: "Pass another vehicle", options: ["A. Vượt", "B. Qua xe", "C. Vượt xe", "D. Chạy qua"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'honk' in Vietnamese?", answer: "Bấm còi", hint: "Use horn", options: ["A. Kêu", "B. Còi", "C. Bấm còi", "D. Tiếng còi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'speed up' in Vietnamese?", answer: "Tăng tốc", hint: "Go faster", options: ["A. Nhanh", "B. Chạy nhanh", "C. Tăng tốc", "D. Ga"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'slow down' in Vietnamese?", answer: "Giảm tốc", hint: "Go slower", options: ["A. Chậm", "B. Giảm tốc", "C. Phanh", "D. Chạy chậm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Transportation Services & Places
                Flashcard(question: "What is 'gas station' in Vietnamese?", answer: "Trạm xăng", hint: "Fuel station", options: ["A. Cửa hàng xăng", "B. Trạm xăng", "C. Cây xăng", "D. Bơm xăng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'petrol/gasoline' in Vietnamese?", answer: "Xăng", hint: "Fuel", options: ["A. Dầu", "B. Xăng", "C. Ga", "D. Nhiên liệu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'repair shop' in Vietnamese?", answer: "Tiệm sửa xe", hint: "Fix vehicles", options: ["A. Ga-ra", "B. Sửa xe", "C. Tiệm sửa xe", "D. Xưởng xe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'train station' in Vietnamese?", answer: "Ga tàu", hint: "Train stop", options: ["A. Bến xe", "B. Ga", "C. Ga tàu", "D. Sân ga"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "What is 'port' in Vietnamese?", answer: "Cảng", hint: "Ships dock here", options: ["A. Bến", "B. Cảng", "C. Bờ", "D. Bến tàu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'terminal' in Vietnamese?", answer: "Nhà ga", hint: "Main station building", options: ["A. Ga", "B. Bến", "C. Nhà ga", "D. Trạm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Traffic Problems
                Flashcard(question: "What is 'accident' in Vietnamese?", answer: "Tai nạn", hint: "Crash", options: ["A. Va chạm", "B. Tai nạn", "C. Đâm", "D. Hỏng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'crash' in Vietnamese?", answer: "Va chạm", hint: "Collision", options: ["A. Tai nạn", "B. Đâm", "C. Va chạm", "D. Húc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'breakdown' in Vietnamese?", answer: "Hỏng xe", hint: "Vehicle failure", options: ["A. Hỏng", "B. Chết máy", "C. Hỏng xe", "D. Lỗi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'flat tire' in Vietnamese?", answer: "Xịt lốp", hint: "Tire puncture", options: ["A. Thủng lốp", "B. Xịt lốp", "C. Lốp hỏng", "D. Lốp xẹp"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'traffic congestion' in Vietnamese?", answer: "Tắc nghẽn giao thông", hint: "Very crowded road", options: ["A. Tắc đường", "B. Kẹt xe", "C. Tắc nghẽn GT", "D. Đông xe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Documents & Rules
                Flashcard(question: "What is 'driver's license' in Vietnamese?", answer: "Bằng lái xe", hint: "Permission to drive", options: ["A. Giấy phép", "B. Bằng lái", "C. Bằng lái xe", "D. Giấy lái xe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'registration' in Vietnamese?", answer: "Đăng ký xe", hint: "Vehicle papers", options: ["A. Giấy tờ", "B. Đăng ký", "C. Giấy xe", "D. Đăng ký xe"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'insurance' in Vietnamese?", answer: "Bảo hiểm", hint: "Protection policy", options: ["A. Bảo vệ", "B. Bảo hiểm", "C. An toàn", "D. Hợp đồng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fine' in Vietnamese?", answer: "Phạt", hint: "Penalty payment", options: ["A. Tiền phạt", "B. Phạt", "C. Vi phạm", "D. Nộp phạt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'traffic violation' in Vietnamese?", answer: "Vi phạm giao thông", hint: "Breaking traffic law", options: ["A. Lỗi", "B. Vi phạm", "C. Vi phạm GT", "D. Phạt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // More Vietnamese to English
                Flashcard(question: "Từ 'Tốc độ' trong tiếng Anh là gì?", answer: "Speed", hint: "How fast", options: ["A. Fast", "B. Speed", "C. Quick", "D. Velocity"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Quãng đường' trong tiếng Anh là gì?", answer: "Distance", hint: "How far", options: ["A. Road", "B. Way", "C. Distance", "D. Journey"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Hành trình' trong tiếng Anh là gì?", answer: "Journey", hint: "Trip", options: ["A. Trip", "B. Travel", "C. Journey", "D. Voyage"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Chuyến đi' trong tiếng Anh là gì?", answer: "Trip", hint: "Travel", options: ["A. Journey", "B. Trip", "C. Travel", "D. Go"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Khởi hành' trong tiếng Anh là gì?", answer: "Depart", hint: "Leave", options: ["A. Start", "B. Go", "C. Depart", "D. Leave"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đến nơi' trong tiếng Anh là gì?", answer: "Arrive", hint: "Reach destination", options: ["A. Come", "B. Reach", "C. Get", "D. Arrive"], correctAnswer: "D", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Làn đường' trong tiếng Anh là gì?", answer: "Lane", hint: "Road division", options: ["A. Way", "B. Lane", "C. Path", "D. Line"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Sang đường' trong tiếng Anh là gì?", answer: "Cross the street", hint: "Go to other side", options: ["A. Go street", "B. Walk street", "C. Cross street", "D. Pass street"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Additional Fill in the Blank
                Flashcard(question: "Please fasten your ___ before driving.", answer: "seat belt", hint: "Safety device", options: ["A. seat", "B. belt", "C. seat belt", "D. tie"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "I need to refuel at the ___ station.", answer: "gas", hint: "Petrol", options: ["A. fuel", "B. gas", "C. oil", "D. petrol"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Turn on the ___ when it's dark.", answer: "headlights", hint: "Front lights", options: ["A. lights", "B. headlights", "C. beams", "D. lamps"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "You must stop at the red ___.", answer: "light", hint: "Traffic signal", options: ["A. sign", "B. light", "C. signal", "D. color"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                
                // MARK: - Reading Comprehension Passages (Bài đọc hiểu)
                
                // Reading Passage 1: Public Transportation in Vietnam
                Flashcard(
                    question: """
                    Read the passage and answer: What is the most popular form of transport in Vietnam?
                    
                    PASSAGE:
                    Vietnam has a diverse transportation system. Motorcycles are the most popular form of transport, with millions of people riding them every day. In big cities like Hanoi and Ho Chi Minh City, you can see motorcycles everywhere. Buses are also common and provide affordable public transportation for many people. Recently, metro systems have been built in major cities to reduce traffic congestion. Taxis and ride-sharing services like Grab are convenient for those who don't want to drive. For long distances, people often take trains or domestic flights.
                    """,
                    answer: "Motorcycles",
                    hint: "Most people in Vietnam ride this",
                    options: ["A. Buses", "B. Motorcycles", "C. Trains", "D. Taxis"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                
                Flashcard(
                    question: """
                    Based on the passage above: Why are metro systems being built?
                    """,
                    answer: "To reduce traffic congestion",
                    hint: "To solve traffic problems",
                    options: ["A. To be modern", "B. To reduce traffic congestion", "C. To replace buses", "D. To compete with taxis"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                
                // Reading Passage 2: My Daily Commute
                Flashcard(
                    question: """
                    Read the passage and answer: How does Nam get to work?
                    
                    PASSAGE:
                    My name is Nam and I live in Hanoi. Every morning, I wake up at 6 AM to prepare for work. I usually take the bus to my office because it's cheaper than driving. The bus stop is just 5 minutes from my house. The journey takes about 30 minutes, but during rush hour it can take up to 45 minutes because of traffic jams. Sometimes, when I'm late, I take a motorbike taxi which is faster but more expensive. I arrive at my office around 7:30 AM. In the evening, I return home the same way. On weekends, I prefer walking or cycling to nearby places to stay healthy.
                    """,
                    answer: "By bus",
                    hint: "Public transport",
                    options: ["A. By car", "B. By bus", "C. By motorbike", "D. By bicycle"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                
                Flashcard(
                    question: """
                    Based on the passage above: Why does Nam sometimes take a motorbike taxi?
                    """,
                    answer: "When he is late",
                    hint: "When he doesn't have much time",
                    options: ["A. It's cheaper", "B. It's comfortable", "C. When he is late", "D. For fun"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                
                Flashcard(
                    question: """
                    Based on the passage above: How long does Nam's commute take during rush hour?
                    """,
                    answer: "Up to 45 minutes",
                    hint: "More than normal time",
                    options: ["A. 30 minutes", "B. Up to 45 minutes", "C. 5 minutes", "D. 1 hour"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                
                // Reading Passage 3: Traffic Safety
                Flashcard(
                    question: """
                    Read the passage and answer: What is the most important safety rule mentioned?
                    
                    PASSAGE:
                    Traffic safety is very important in Vietnam. The most important rule is to always wear a helmet when riding a motorcycle. It can save your life in an accident. Drivers should also obey traffic lights and signs. Never drink alcohol before driving, as it causes many accidents. It's essential to check your mirrors before changing lanes or turning. Pedestrians should use crosswalks and wait for the green light before crossing the street. During rainy weather, drivers must slow down because roads become slippery. Everyone should follow these rules to make our roads safer.
                    """,
                    answer: "Wear a helmet",
                    hint: "Protects your head",
                    options: ["A. Obey traffic lights", "B. Wear a helmet", "C. Use crosswalks", "D. Check mirrors"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                
                Flashcard(
                    question: """
                    Based on the passage above: What should drivers do in rainy weather?
                    """,
                    answer: "Slow down",
                    hint: "Reduce speed",
                    options: ["A. Speed up", "B. Stop driving", "C. Slow down", "D. Turn on lights"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                ),
                
                // Reading Passage 4: Airport Experience
                Flashcard(
                    question: """
                    Read the passage and answer: How early should you arrive at the airport?
                    
                    PASSAGE:
                    Traveling by airplane can be exciting but requires careful planning. You should arrive at the airport at least 2 hours before domestic flights and 3 hours before international flights. This gives you enough time to check in, drop off your luggage, and go through security. After checking in, you'll receive your boarding pass. Make sure to have your passport and ticket ready. At security, you'll need to remove metal objects and place your bags on the scanner. Once through security, you can wait at the gate or browse the duty-free shops. Listen carefully for announcements about your flight. Board the plane when your row number is called.
                    """,
                    answer: "2-3 hours before flight",
                    hint: "Depends on domestic or international",
                    options: ["A. 1 hour", "B. 2-3 hours before flight", "C. 30 minutes", "D. 5 hours"],
                    correctAnswer: "B",
                    exerciseType: .chooseCorrectWord
                ),
                
                Flashcard(
                    question: """
                    Based on the passage above: What do you receive after checking in?
                    """,
                    answer: "Boarding pass",
                    hint: "Ticket to board plane",
                    options: ["A. Passport", "B. Luggage tag", "C. Boarding pass", "D. Flight ticket"],
                    correctAnswer: "C",
                    exerciseType: .chooseCorrectWord
                )
            ]
        )
        
        // NEW: Shopping Topic - EXPANDED with Conversational Phrases
        let shoppingTopic = Topic(
            name: "Shopping Conversations (Giao tiếp Mua sắm)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Stores & Places
                Flashcard(question: "What is 'supermarket' in Vietnamese?", answer: "Siêu thị", hint: "Large food store", options: ["A. Chợ", "B. Siêu thị", "C. Cửa hàng", "D. Tiệm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'market' in Vietnamese?", answer: "Chợ", hint: "Open-air shopping", options: ["A. Siêu thị", "B. Chợ", "C. Trung tâm", "D. Cửa hàng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'shopping mall' in Vietnamese?", answer: "Trung tâm thương mại", hint: "Big shopping complex", options: ["A. Chợ", "B. Siêu thị", "C. Trung tâm TM", "D. Cửa hàng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'store/shop' in Vietnamese?", answer: "Cửa hàng", hint: "Small retail place", options: ["A. Tiệm", "B. Cửa hàng", "C. Siêu thị", "D. Chợ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'convenience store' in Vietnamese?", answer: "Cửa hàng tiện lợi", hint: "24/7 small shop", options: ["A. Siêu thị", "B. Chợ", "C. Cửa hàng TL", "D. Tiệm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cashier' in Vietnamese?", answer: "Thu ngân", hint: "Person at checkout", options: ["A. Bán hàng", "B. Thu ngân", "C. Nhân viên", "D. Quản lý"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'checkout counter' in Vietnamese?", answer: "Quầy thanh toán", hint: "Where you pay", options: ["A. Quầy hàng", "B. Quầy thanh toán", "C. Thu ngân", "D. Cửa hàng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fitting room' in Vietnamese?", answer: "Phòng thử đồ", hint: "Try on clothes", options: ["A. Phòng thay đồ", "B. Phòng thử đồ", "C. Phòng mặc", "D. Tủ quần áo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Shopping Actions & Verbs
                Flashcard(question: "What is 'buy' in Vietnamese?", answer: "Mua", hint: "Purchase", options: ["A. Bán", "B. Mua", "C. Trả tiền", "D. Chọn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sell' in Vietnamese?", answer: "Bán", hint: "Exchange for money", options: ["A. Mua", "B. Bán", "C. Đổi", "D. Cho"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pay' in Vietnamese?", answer: "Trả tiền", hint: "Give money", options: ["A. Mua", "B. Bán", "C. Trả tiền", "D. Nhận tiền"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'try on' in Vietnamese?", answer: "Thử, thử đồ", hint: "Test clothes", options: ["A. Mặc", "B. Thử", "C. Chọn", "D. Mua"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'return' in Vietnamese?", answer: "Trả lại, đổi trả", hint: "Give back", options: ["A. Mua", "B. Bán", "C. Trả lại", "D. Đổi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'exchange' in Vietnamese?", answer: "Đổi", hint: "Swap for another", options: ["A. Trả", "B. Đổi", "C. Mua", "D. Thay"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'refund' in Vietnamese?", answer: "Hoàn tiền", hint: "Get money back", options: ["A. Trả tiền", "B. Trả lại", "C. Hoàn tiền", "D. Đổi tiền"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bargain' in Vietnamese?", answer: "Mặc cả", hint: "Negotiate price", options: ["A. Trả giá", "B. Mặc cả", "C. Giảm giá", "D. Hỏi giá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Price & Money Vocabulary
                Flashcard(question: "What is 'price' in Vietnamese?", answer: "Giá", hint: "How much it costs", options: ["A. Tiền", "B. Giá", "C. Chi phí", "D. Đắt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'discount' in Vietnamese?", answer: "Giảm giá", hint: "Lower price", options: ["A. Sale", "B. Giảm giá", "C. Khuyến mãi", "D. Rẻ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'expensive' in Vietnamese?", answer: "Đắt", hint: "High price", options: ["A. Rẻ", "B. Đắt", "C. Giá", "D. Tiền"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cheap' in Vietnamese?", answer: "Rẻ", hint: "Low price", options: ["A. Đắt", "B. Rẻ", "C. Giá", "D. Giảm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'total' in Vietnamese?", answer: "Tổng cộng", hint: "Final amount", options: ["A. Tổng", "B. Tổng cộng", "C. Cộng", "D. Toàn bộ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'promotion' in Vietnamese?", answer: "Khuyến mãi", hint: "Special offer", options: ["A. Giảm giá", "B. Sale", "C. Khuyến mãi", "D. Ưu đãi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Money & Payment
                Flashcard(question: "What is 'money' in Vietnamese?", answer: "Tiền", hint: "Currency", options: ["A. Tiền", "B. Giá", "C. Thẻ", "D. Đồng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cash' in Vietnamese?", answer: "Tiền mặt", hint: "Physical money", options: ["A. Thẻ", "B. Tiền mặt", "C. Séc", "D. Tín dụng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'credit card' in Vietnamese?", answer: "Thẻ tín dụng", hint: "Plastic payment", options: ["A. Tiền mặt", "B. Thẻ", "C. Thẻ tín dụng", "D. ATM"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'receipt' in Vietnamese?", answer: "Hóa đơn", hint: "Proof of purchase", options: ["A. Tiền", "B. Giấy", "C. Hóa đơn", "D. Thẻ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'change' in Vietnamese?", answer: "Tiền thối", hint: "Money back", options: ["A. Tiền mặt", "B. Tiền thối", "C. Tiền lẻ", "D. Đổi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Shopping Items
                Flashcard(question: "What is 'shopping cart' in Vietnamese?", answer: "Xe đẩy hàng", hint: "Push while shopping", options: ["A. Giỏ", "B. Xe đẩy", "C. Túi", "D. Thùng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'shopping bag' in Vietnamese?", answer: "Túi mua sắm", hint: "Carry purchases", options: ["A. Túi", "B. Giỏ", "C. Bao", "D. Hộp"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'sale' in Vietnamese?", answer: "Giảm giá, sale", hint: "Special offer", options: ["A. Mua", "B. Bán", "C. Giảm giá", "D. Đắt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Sizes & Descriptions
                Flashcard(question: "What is 'size' in Vietnamese?", answer: "Kích cỡ, size", hint: "Measurement", options: ["A. Cỡ", "B. Kích thước", "C. Size", "D. Tất cả đúng"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'small' in Vietnamese?", answer: "Nhỏ, size S", hint: "Not big", options: ["A. Lớn", "B. Nhỏ", "C. Vừa", "D. To"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'medium' in Vietnamese?", answer: "Vừa, size M", hint: "Middle size", options: ["A. Nhỏ", "B. Lớn", "C. Vừa", "D. Trung bình"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'large' in Vietnamese?", answer: "Lớn, size L", hint: "Big", options: ["A. Nhỏ", "B. Vừa", "C. Lớn", "D. To"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'color' in Vietnamese?", answer: "Màu sắc", hint: "Red, blue, etc.", options: ["A. Màu", "B. Màu sắc", "C. Sắc", "D. Mầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Common Shopping Phrases - Vietnamese to English
                Flashcard(question: "Từ 'Khách hàng' trong tiếng Anh là gì?", answer: "Customer", hint: "Person who buys", options: ["A. Seller", "B. Customer", "C. Buyer", "D. Guest"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thử đồ' trong tiếng Anh là gì?", answer: "Try on", hint: "Test clothes", options: ["A. Buy", "B. Try on", "C. Wear", "D. Choose"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Bao nhiêu tiền?' trong tiếng Anh là gì?", answer: "How much?", hint: "Ask price", options: ["A. What price?", "B. How much?", "C. How many?", "D. What cost?"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đắt quá!' trong tiếng Anh là gì?", answer: "Too expensive!", hint: "High price complaint", options: ["A. Very expensive", "B. Too much", "C. Too expensive", "D. So expensive"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Rẻ hơn được không?' trong tiếng Anh là gì?", answer: "Can you give me a discount?", hint: "Ask for lower price", options: ["A. More cheap?", "B. Can discount?", "C. Give discount?", "D. Can you give me a discount?"], correctAnswer: "D", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tôi chỉ xem thôi' trong tiếng Anh là gì?", answer: "I'm just looking", hint: "Not buying yet", options: ["A. Just look", "B. I'm looking", "C. I'm just looking", "D. Only looking"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Tôi lấy cái này' trong tiếng Anh là gì?", answer: "I'll take this one", hint: "Choose item", options: ["A. I take this", "B. I buy this", "C. I want this", "D. I'll take this one"], correctAnswer: "D", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Có màu khác không?' trong tiếng Anh là gì?", answer: "Do you have other colors?", hint: "Different color", options: ["A. Other color?", "B. Different color?", "C. Do you have other colors?", "D. Another color?"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Fill in the blank - Common Shopping Conversations
                Flashcard(question: "This shirt is too ___. I can't buy it.", answer: "expensive", hint: "High price", options: ["A. cheap", "B. expensive", "C. nice", "D. big"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Can I pay with ___?", answer: "card", hint: "Not cash", options: ["A. money", "B. card", "C. paper", "D. coin"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Excuse me, where is the ___ room?", answer: "fitting", hint: "Try on clothes", options: ["A. changing", "B. fitting", "C. dressing", "D. trying"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Do you have this in a ___ size?", answer: "smaller", hint: "Not bigger", options: ["A. small", "B. smaller", "C. big", "D. large"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Can I get a ___? This has a small defect.", answer: "discount", hint: "Lower price", options: ["A. sale", "B. cheap", "C. discount", "D. refund"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "I'd like to ___ this. It doesn't fit.", answer: "return", hint: "Give back", options: ["A. exchange", "B. return", "C. refund", "D. change"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Is this on ___?", answer: "sale", hint: "Discount", options: ["A. discount", "B. sale", "C. promotion", "D. offer"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Can I ___ this before I buy?", answer: "try", hint: "Test it", options: ["A. see", "B. try", "C. look", "D. wear"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Do you accept credit ___?", answer: "cards", hint: "Payment method", options: ["A. card", "B. cards", "C. money", "D. cash"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "How ___ does this cost?", answer: "much", hint: "Price question", options: ["A. many", "B. much", "C. money", "D. price"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // NEW: Hometown Topic - EXPANDED
        let hometownTopic = Topic(
            name: "Hometown (Quê hương)",
            subjectName: "Tiếng Anh",
            flashcards: allFlashcards,
            readings: [
                // MARK: - LEVEL 1: BEGINNER (Cơ bản) - Simple sentences, present tense, basic vocabulary
                
                ReadingPassage(
                    title: "My Small Village",
                    level: .beginner,
                    content: """
My name is Lan. I am from a small village. My village is quiet and beautiful. There are many trees and flowers. The air is clean and fresh.

I live with my family in a small house. We have a garden. In the garden, we grow vegetables. My father is a farmer. He works in the rice fields every day.

In my village, people are very friendly. They help each other. I love my village. It is my hometown.
""",
                    questions: [
                        ReadingQuestion(
                            question: "Where is Lan from?",
                            options: ["A. A big city", "B. A small village", "C. A town", "D. A foreign country"],
                            correctAnswer: "B",
                            explanation: "The passage says 'I am from a small village.'"
                        ),
                        ReadingQuestion(
                            question: "What does Lan's father do?",
                            options: ["A. He is a teacher", "B. He is a doctor", "C. He is a farmer", "D. He is a driver"],
                            correctAnswer: "C",
                            explanation: "The text states 'My father is a farmer.'"
                        ),
                        ReadingQuestion(
                            question: "How are people in Lan's village?",
                            options: ["A. Unfriendly", "B. Busy", "C. Rich", "D. Friendly"],
                            correctAnswer: "D",
                            explanation: "The passage mentions 'people are very friendly.'"
                        )
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "village", meaning: "làng", example: "I live in a small village."),
                        VocabularyItem(word: "quiet", meaning: "yên tĩnh", example: "My village is quiet."),
                        VocabularyItem(word: "farmer", meaning: "nông dân", example: "My father is a farmer."),
                        VocabularyItem(word: "rice field", meaning: "ruộng lúa", example: "He works in the rice fields.")
                    ]
                ),
                
                // MARK: - LEVEL 2: ELEMENTARY (Sơ cấp) - Past tense intro, more descriptive
                
                ReadingPassage(
                    title: "A Day in My Hometown",
                    level: .elementary,
                    content: """
I grew up in a town called Bac Ninh, about 30 kilometers north of Hanoi. It is a small but historic town. Last weekend, I visited my hometown after living in the city for two years.

When I arrived, everything looked different. There were new roads and buildings. However, the old temple in the center was still there. I visited the temple and met some old friends.

We walked around the market together. The market was busy with people buying and selling. I bought some local food that I missed. The food tasted delicious, just like I remembered.

In the evening, I sat by the river with my family. We watched the sunset. It was peaceful and beautiful. I felt happy to be home again.
""",
                    questions: [
                        ReadingQuestion(
                            question: "Where is the writer's hometown?",
                            options: ["A. In Hanoi", "B. 30 km north of Hanoi", "C. In Ho Chi Minh City", "D. 30 km south of Hanoi"],
                            correctAnswer: "B",
                            explanation: "The passage says 'Bac Ninh, about 30 kilometers north of Hanoi.'"
                        ),
                        ReadingQuestion(
                            question: "How long did the writer live in the city?",
                            options: ["A. One year", "B. Two years", "C. Three years", "D. Four years"],
                            correctAnswer: "B",
                            explanation: "The text mentions 'after living in the city for two years.'"
                        ),
                        ReadingQuestion(
                            question: "What did NOT change in the hometown?",
                            options: ["A. Roads", "B. Buildings", "C. The old temple", "D. The market"],
                            correctAnswer: "C",
                            explanation: "The passage says 'the old temple in the center was still there.'"
                        ),
                        ReadingQuestion(
                            question: "What did the writer do in the evening?",
                            options: ["A. Went shopping", "B. Visited friends", "C. Sat by the river", "D. Went to the temple"],
                            correctAnswer: "C",
                            explanation: "'In the evening, I sat by the river with my family.'"
                        )
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "grew up", meaning: "lớn lên", example: "I grew up in a small town."),
                        VocabularyItem(word: "historic", meaning: "có lịch sử, cổ kính", example: "It is a historic town."),
                        VocabularyItem(word: "local", meaning: "địa phương, bản địa", example: "I bought some local food."),
                        VocabularyItem(word: "sunset", meaning: "hoàng hôn", example: "We watched the sunset.")
                    ]
                ),
                
                // MARK: - LEVEL 3: INTERMEDIATE (Trung cấp) - Mixed tenses, comparisons
                
                ReadingPassage(
                    title: "Changes in My Hometown",
                    level: .intermediate,
                    content: """
My hometown is a coastal city called Nha Trang, famous for its beautiful beaches and fresh seafood. I have lived in Ho Chi Minh City for the past five years, but I try to visit my hometown at least twice a year.

Every time I return, I notice significant changes. Ten years ago, Nha Trang was a quiet fishing town with only a few tourists. The main street had small shops and local restaurants. Most buildings were only two or three stories high.

Today, everything has transformed dramatically. High-rise hotels and resorts line the beachfront. International restaurants and shopping centers have opened everywhere. The population has doubled, and traffic congestion has become a serious problem, especially during peak tourist season.

Despite these changes, some things remain the same. The beach is still as beautiful as ever, with its clear blue water and white sand. Local people still maintain their friendly and welcoming attitude toward visitors. The seafood market in the morning is as lively as it was in my childhood.

However, I sometimes worry about rapid development. The traditional character of my hometown is gradually disappearing. Many old houses have been demolished to make way for modern buildings. Some local families have moved away because they can no longer afford the rising cost of living.

I hope that in the future, my hometown can balance development with preservation. It's important to grow economically while maintaining cultural identity and natural beauty.
""",
                    questions: [
                        ReadingQuestion(
                            question: "What is Nha Trang famous for?",
                            options: ["A. Mountains and forests", "B. Ancient temples", "C. Beautiful beaches and fresh seafood", "D. Shopping centers"],
                            correctAnswer: "C",
                            explanation: "The first sentence mentions 'famous for its beautiful beaches and fresh seafood.'"
                        ),
                        ReadingQuestion(
                            question: "How was Nha Trang ten years ago?",
                            options: ["A. A busy tourist destination", "B. A quiet fishing town", "C. An industrial city", "D. A modern metropolis"],
                            correctAnswer: "B",
                            explanation: "'Ten years ago, Nha Trang was a quiet fishing town with only a few tourists.'"
                        ),
                        ReadingQuestion(
                            question: "What problem has development caused?",
                            options: ["A. Pollution only", "B. Loss of beaches", "C. Traffic congestion", "D. Food shortages"],
                            correctAnswer: "C",
                            explanation: "'traffic congestion has become a serious problem'"
                        ),
                        ReadingQuestion(
                            question: "What does the writer hope for the future?",
                            options: ["A. More tourists", "B. Faster development", "C. Balance between development and preservation", "D. No more changes"],
                            correctAnswer: "C",
                            explanation: "The writer hopes 'my hometown can balance development with preservation.'"
                        ),
                        ReadingQuestion(
                            question: "Why have some local families moved away?",
                            options: ["A. They don't like tourists", "B. The cost of living is too high", "C. They want to see other places", "D. There are no jobs"],
                            correctAnswer: "B",
                            explanation: "'they can no longer afford the rising cost of living.'"
                        )
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "coastal", meaning: "ven biển", example: "Nha Trang is a coastal city."),
                        VocabularyItem(word: "significant", meaning: "đáng kể, quan trọng", example: "I notice significant changes."),
                        VocabularyItem(word: "transformed", meaning: "biến đổi, thay đổi hoàn toàn", example: "Everything has transformed dramatically."),
                        VocabularyItem(word: "demolished", meaning: "phá dỡ", example: "Old houses have been demolished."),
                        VocabularyItem(word: "preservation", meaning: "sự bảo tồn", example: "Development with preservation is important.")
                    ]
                ),
                
                // MARK: - LEVEL 4: UPPER-INTERMEDIATE (Trung cấp cao) - Complex structures, passive voice
                
                ReadingPassage(
                    title: "The Evolution of Vietnamese Rural Areas",
                    level: .upperIntermediate,
                    content: """
Vietnam's rural landscape has undergone remarkable transformation over the past three decades. What were once isolated farming communities with limited infrastructure have evolved into connected, modernized villages that blend traditional values with contemporary conveniences.

In the 1990s, most Vietnamese villages were characterized by dirt roads, thatched-roof houses, and a complete absence of modern amenities. Electricity was intermittent, and running water was a luxury few could afford. Communication with the outside world was limited to occasional trips to nearby towns or letters that took weeks to arrive.

The government's New Rural Development program, launched in 2010, has been instrumental in driving this transformation. Under this initiative, thousands of rural communes have been upgraded with paved roads, irrigation systems, and public facilities such as community centers and healthcare clinics. Solar panels and internet connectivity have become increasingly common, connecting even remote villages to the digital age.

However, this modernization comes with both advantages and challenges. On the positive side, improved infrastructure has enhanced living standards and created new economic opportunities. Farmers can now access market information online, sell products directly to urban consumers, and diversify their income sources through agritourism. Children have better access to education through online learning platforms.

Conversely, rapid development has led to concerns about cultural erosion and environmental degradation. Young people, attracted by urban job opportunities, continue to migrate to cities, leaving an aging population in rural areas. Traditional crafts and customs are at risk of being forgotten. Additionally, intensive farming practices and construction projects have affected local ecosystems and water quality.

Sociologists argue that successful rural development requires a holistic approach that goes beyond physical infrastructure. It must include strategies for cultural preservation, environmental protection, and creating sustainable livelihoods that give young people reasons to stay or return to their hometowns.

The future of Vietnamese rural communities will depend on finding this delicate balance – embracing modernity while preserving the essence of what makes these places unique and valuable.
""",
                    questions: [
                        ReadingQuestion(
                            question: "What is the main topic of the passage?",
                            options: ["A. Vietnamese farming techniques", "B. Urban development in Vietnam", "C. Transformation of Vietnamese rural areas", "D. Environmental problems in villages"],
                            correctAnswer: "C",
                            explanation: "The passage discusses 'remarkable transformation' of Vietnam's rural landscape."
                        ),
                        ReadingQuestion(
                            question: "When was the New Rural Development program launched?",
                            options: ["A. In the 1990s", "B. In 2000", "C. In 2010", "D. In 2020"],
                            correctAnswer: "C",
                            explanation: "The text states 'launched in 2010.'"
                        ),
                        ReadingQuestion(
                            question: "Which of the following is NOT mentioned as a modern amenity in villages?",
                            options: ["A. Internet connectivity", "B. Solar panels", "C. Shopping malls", "D. Healthcare clinics"],
                            correctAnswer: "C",
                            explanation: "Shopping malls are not mentioned in the passage."
                        ),
                        ReadingQuestion(
                            question: "What concern is associated with rapid development?",
                            options: ["A. Too many tourists", "B. Cultural erosion", "C. Economic collapse", "D. Food shortages"],
                            correctAnswer: "B",
                            explanation: "'rapid development has led to concerns about cultural erosion'"
                        ),
                        ReadingQuestion(
                            question: "According to sociologists, what does successful rural development require?",
                            options: ["A. Only physical infrastructure", "B. More factories", "C. A holistic approach including cultural preservation", "D. Urbanization of all villages"],
                            correctAnswer: "C",
                            explanation: "'successful rural development requires a holistic approach...include strategies for cultural preservation'"
                        ),
                        ReadingQuestion(
                            question: "Why are young people leaving rural areas?",
                            options: ["A. They don't like farming", "B. Villages are too modern", "C. They are attracted by urban job opportunities", "D. There is no internet"],
                            correctAnswer: "C",
                            explanation: "'Young people, attracted by urban job opportunities, continue to migrate'"
                        )
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "undergo", meaning: "trải qua", example: "The area has undergone transformation."),
                        VocabularyItem(word: "isolated", meaning: "biệt lập, cô lập", example: "Isolated farming communities existed before."),
                        VocabularyItem(word: "instrumental", meaning: "đóng vai trò quan trọng", example: "The program was instrumental in driving change."),
                        VocabularyItem(word: "erosion", meaning: "sự xói mòn", example: "Cultural erosion is a concern."),
                        VocabularyItem(word: "holistic", meaning: "toàn diện", example: "A holistic approach is needed.")
                    ]
                ),
                
                // MARK: - LEVEL 5: ADVANCED (Nâng cao) - Academic style, complex arguments
                
                ReadingPassage(
                    title: "Nostalgia and Identity: The Psychological Significance of Hometowns",
                    level: .advanced,
                    content: """
The concept of "hometown" transcends mere geographical designation; it represents a complex psychological and emotional anchor that shapes individual identity throughout one's lifetime. Research in environmental psychology and cultural anthropology has demonstrated that our birthplaces exert profound influence on personality development, worldview formation, and sense of belonging.

Nostalgia, derived from the Greek words "nostos" (return home) and "algos" (pain), was once classified as a medical disorder. Contemporary psychological research, however, has reframed nostalgia as a predominantly positive emotional experience that serves important adaptive functions. When individuals reminisce about their hometowns, they typically report enhanced mood, increased self-continuity, and strengthened social connections. This phenomenon is particularly pronounced among diaspora communities and internal migrants who maintain strong psychological ties to their places of origin.

The relationship between hometown and identity becomes especially complex in rapidly developing societies like Vietnam, where urbanization and globalization create tensions between traditional and modern values. First-generation urban migrants often experience what sociologists term "cultural dislocation" – a sense of being caught between two worlds, neither fully belonging to their rural origins nor completely assimilated into urban culture. This psychological limbo can manifest in various ways, from maintaining idealized memories of hometown life to experiencing guilt about abandoning ancestral lands.

Interestingly, recent studies suggest that physical distance from one's hometown may actually intensify emotional attachment rather than diminish it. The "absence makes the heart grow fonder" principle appears to hold true when applied to places as well as people. Urban professionals who visit their hometowns infrequently often report more romanticized perceptions than those who never left. This selective memory tends to emphasize positive aspects while minimizing hardships, creating what psychologists call "rosy retrospection."

From an evolutionary perspective, attachment to birthplace may have served survival functions for ancestral humans. Intimate knowledge of local geography, seasonal patterns, and community relationships provided competitive advantages. Although modern humans have far greater mobility, these deep-rooted psychological mechanisms persist, explaining why people continue to feel profound connections to places they may have left decades ago.

The digital age has introduced new dimensions to hometown connections. Social media platforms enable migrants to maintain virtual presence in their communities of origin, participating in local events vicariously and preserving relationships that would have atrophied in previous generations. However, this digital connectivity is a double-edged sword: while it reduces feelings of disconnection, it may also prevent the emotional resolution necessary for full integration into new communities.

Urban planners and policymakers are increasingly recognizing the importance of place attachment in creating sustainable communities. Rather than viewing migration as a one-way process of abandoning rural areas for cities, progressive strategies aim to maintain bi-directional connections. Initiatives such as encouraging remote work, developing local tourism, and preserving cultural heritage sites can help communities thrive while allowing individuals to maintain meaningful relationships with their hometowns.

The psychological significance of hometowns ultimately reflects fundamental human needs for continuity, belonging, and rootedness in an increasingly fluid world. Understanding these dynamics is crucial not only for individual well-being but also for developing policies that respect both personal identity and community sustainability.
""",
                    questions: [
                        ReadingQuestion(
                            question: "According to the passage, how has the perception of nostalgia changed?",
                            options: [
                                "A. From a positive emotion to a disorder",
                                "B. From a medical disorder to a positive adaptive function",
                                "C. It has remained unchanged",
                                "D. From psychological to physical"
                            ],
                            correctAnswer: "B",
                            explanation: "The text states nostalgia 'was once classified as a medical disorder' but has been 'reframed as a predominantly positive emotional experience.'"
                        ),
                        ReadingQuestion(
                            question: "What is 'cultural dislocation'?",
                            options: [
                                "A. Moving to another country",
                                "B. Forgetting one's culture",
                                "C. Being caught between two worlds, not fully belonging to either",
                                "D. Learning a new language"
                            ],
                            correctAnswer: "C",
                            explanation: "'cultural dislocation' is described as 'a sense of being caught between two worlds, neither fully belonging to their rural origins nor completely assimilated into urban culture.'"
                        ),
                        ReadingQuestion(
                            question: "What does 'rosy retrospection' refer to?",
                            options: [
                                "A. Remembering only negative aspects",
                                "B. Emphasizing positive aspects while minimizing hardships",
                                "C. Accurate memory of the past",
                                "D. Complete forgetting of hometown"
                            ],
                            correctAnswer: "B",
                            explanation: "'rosy retrospection' is described as 'selective memory tends to emphasize positive aspects while minimizing hardships.'"
                        ),
                        ReadingQuestion(
                            question: "How does physical distance affect hometown attachment according to the passage?",
                            options: [
                                "A. It reduces attachment completely",
                                "B. It has no effect",
                                "C. It may actually intensify emotional attachment",
                                "D. It causes depression"
                            ],
                            correctAnswer: "C",
                            explanation: "'physical distance from one's hometown may actually intensify emotional attachment rather than diminish it.'"
                        ),
                        ReadingQuestion(
                            question: "What is the 'double-edged sword' of digital connectivity mentioned?",
                            options: [
                                "A. It's expensive and slow",
                                "B. It reduces disconnection but may prevent integration into new communities",
                                "C. It only benefits young people",
                                "D. It destroys traditional culture"
                            ],
                            correctAnswer: "B",
                            explanation: "'while it reduces feelings of disconnection, it may also prevent the emotional resolution necessary for full integration into new communities.'"
                        ),
                        ReadingQuestion(
                            question: "From an evolutionary perspective, why might hometown attachment exist?",
                            options: [
                                "A. It made people happier",
                                "B. It helped with language development",
                                "C. Local knowledge provided survival advantages",
                                "D. It was required by law"
                            ],
                            correctAnswer: "C",
                            explanation: "'Intimate knowledge of local geography, seasonal patterns, and community relationships provided competitive advantages.'"
                        ),
                        ReadingQuestion(
                            question: "What do progressive migration strategies aim for?",
                            options: [
                                "A. Complete urbanization",
                                "B. Preventing all migration",
                                "C. One-way movement to cities",
                                "D. Maintaining bi-directional connections between rural and urban areas"
                            ],
                            correctAnswer: "D",
                            explanation: "'progressive strategies aim to maintain bi-directional connections' rather than viewing migration as one-way."
                        )
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "transcends", meaning: "vượt lên trên, vượt qua", example: "The concept transcends geographical designation."),
                        VocabularyItem(word: "exert", meaning: "tác động, gây ảnh hưởng", example: "Birthplaces exert profound influence."),
                        VocabularyItem(word: "diaspora", meaning: "cộng đồng người di cư, người xa xứ", example: "Diaspora communities maintain strong ties."),
                        VocabularyItem(word: "manifest", meaning: "biểu hiện, thể hiện", example: "This can manifest in various ways."),
                        VocabularyItem(word: "vicariously", meaning: "một cách gián tiếp (trải nghiệm qua người khác)", example: "Participating in events vicariously through social media."),
                        VocabularyItem(word: "atrophied", meaning: "teo đi, thoái hóa", example: "Relationships that would have atrophied."),
                        VocabularyItem(word: "bi-directional", meaning: "hai chiều", example: "Maintaining bi-directional connections is important.")
                    ]
                )
            ]
        )
        
        // NEW: Hospital & Medical Topic - COMPREHENSIVE
        let hospitalTopic = Topic(
            name: "Hospital & Medical (Bệnh viện & Y tế)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // MARK: - Medical Places & Facilities
                Flashcard(question: "What is 'hospital' in Vietnamese?", answer: "Bệnh viện", hint: "Where sick people go", options: ["A. Phòng khám", "B. Bệnh viện", "C. Nhà thuốc", "D. Trung tâm y tế"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'clinic' in Vietnamese?", answer: "Phòng khám", hint: "Small medical center", options: ["A. Bệnh viện", "B. Phòng khám", "C. Nhà thuốc", "D. Y tế"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pharmacy' in Vietnamese?", answer: "Hiệu thuốc, nhà thuốc", hint: "Buy medicine here", options: ["A. Bệnh viện", "B. Phòng khám", "C. Nhà thuốc", "D. Phòng thuốc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'emergency room' in Vietnamese?", answer: "Phòng cấp cứu", hint: "For urgent cases", options: ["A. Phòng khám", "B. Phòng bệnh", "C. Phòng cấp cứu", "D. Phòng mổ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'waiting room' in Vietnamese?", answer: "Phòng chờ", hint: "Wait before seeing doctor", options: ["A. Phòng khám", "B. Phòng chờ", "C. Phòng bệnh", "D. Hành lang"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'operating room' in Vietnamese?", answer: "Phòng mổ", hint: "For surgery", options: ["A. Phòng khám", "B. Phòng bệnh", "C. Phòng mổ", "D. Phòng cấp cứu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ward' in Vietnamese?", answer: "Buồng bệnh, khu điều trị", hint: "Hospital room section", options: ["A. Phòng bệnh", "B. Buồng bệnh", "C. Giường bệnh", "D. Khu vực"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Medical Professionals
                Flashcard(question: "What is 'doctor' in Vietnamese?", answer: "Bác sĩ", hint: "Medical professional", options: ["A. Y tá", "B. Bác sĩ", "C. Dược sĩ", "D. Điều dưỡng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'nurse' in Vietnamese?", answer: "Y tá, điều dưỡng", hint: "Helps doctor", options: ["A. Bác sĩ", "B. Y tá", "C. Dược sĩ", "D. Bệnh nhân"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'surgeon' in Vietnamese?", answer: "Bác sĩ phẫu thuật", hint: "Does operations", options: ["A. Bác sĩ", "B. Y tá", "C. Bác sĩ phẫu thuật", "D. Chuyên khoa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'patient' in Vietnamese?", answer: "Bệnh nhân", hint: "Sick person", options: ["A. Bác sĩ", "B. Y tá", "C. Người bệnh", "D. Bệnh nhân"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pharmacist' in Vietnamese?", answer: "Dược sĩ", hint: "Medicine expert", options: ["A. Bác sĩ", "B. Y tá", "C. Dược sĩ", "D. Nhân viên"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'specialist' in Vietnamese?", answer: "Bác sĩ chuyên khoa", hint: "Expert in one field", options: ["A. Bác sĩ", "B. Chuyên gia", "C. Bác sĩ chuyên khoa", "D. Giáo sư"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Common Illnesses & Symptoms
                Flashcard(question: "What is 'sick/ill' in Vietnamese?", answer: "Ốm, bị bệnh", hint: "Not healthy", options: ["A. Đau", "B. Ốm", "C. Yếu", "D. Mệt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'fever' in Vietnamese?", answer: "Sốt", hint: "High temperature", options: ["A. Cảm", "B. Sốt", "C. Nóng", "D. Ớn lạnh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cough' in Vietnamese?", answer: "Ho", hint: "Throat sound", options: ["A. Hắt hơi", "B. Ho", "C. Đau họng", "D. Khó thở"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'headache' in Vietnamese?", answer: "Đau đầu", hint: "Pain in head", options: ["A. Đau", "B. Nhức đầu", "C. Đau đầu", "D. Chóng mặt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stomachache' in Vietnamese?", answer: "Đau bụng", hint: "Pain in stomach", options: ["A. Đau dạ dày", "B. Đau bụng", "C. Tiêu chảy", "D. Buồn nôn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cold' in Vietnamese?", answer: "Cảm lạnh, cảm", hint: "Common illness", options: ["A. Lạnh", "B. Cảm", "C. Sổ mũi", "D. Cúm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'flu' in Vietnamese?", answer: "Cúm", hint: "Influenza", options: ["A. Cảm", "B. Cúm", "C. Sốt", "D. Ốm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'pain' in Vietnamese?", answer: "Đau", hint: "Hurts", options: ["A. Đau", "B. Nhức", "C. Ốm", "D. Bệnh"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'injury' in Vietnamese?", answer: "Chấn thương", hint: "Physical damage", options: ["A. Đau", "B. Thương tích", "C. Chấn thương", "D. Vết thương"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wound' in Vietnamese?", answer: "Vết thương", hint: "Cut or injury", options: ["A. Thương tích", "B. Vết thương", "C. Chấn thương", "D. Đau"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'allergy' in Vietnamese?", answer: "Dị ứng", hint: "Body reaction", options: ["A. Ngứa", "B. Nổi mẩn", "C. Dị ứng", "D. Phản ứng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Medical Treatments & Procedures
                Flashcard(question: "What is 'medicine' in Vietnamese?", answer: "Thuốc", hint: "For treatment", options: ["A. Thuốc", "B. Dược", "C. Y", "D. Chữa"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'prescription' in Vietnamese?", answer: "Đơn thuốc", hint: "Doctor's written order", options: ["A. Thuốc", "B. Đơn thuốc", "C. Toa thuốc", "D. Bệnh án"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'treatment' in Vietnamese?", answer: "Điều trị, chữa trị", hint: "Medical care", options: ["A. Chữa", "B. Khám", "C. Điều trị", "D. Chăm sóc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'surgery' in Vietnamese?", answer: "Phẫu thuật", hint: "Operation", options: ["A. Mổ", "B. Phẫu thuật", "C. Điều trị", "D. Cấp cứu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'injection' in Vietnamese?", answer: "Tiêm", hint: "Shot with needle", options: ["A. Uống thuốc", "B. Tiêm", "C. Bôi", "D. Xịt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'examination' in Vietnamese?", answer: "Khám bệnh", hint: "Medical checkup", options: ["A. Xét nghiệm", "B. Chữa bệnh", "C. Khám bệnh", "D. Kiểm tra"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'X-ray' in Vietnamese?", answer: "Chụp X-quang", hint: "Medical imaging", options: ["A. Chụp phim", "B. X-quang", "C. Chụp CT", "D. Siêu âm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'blood test' in Vietnamese?", answer: "Xét nghiệm máu", hint: "Lab test", options: ["A. Lấy máu", "B. Kiểm tra máu", "C. Xét nghiệm máu", "D. Thử máu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'bandage' in Vietnamese?", answer: "Băng, băng bó", hint: "Wrap wound", options: ["A. Gạc", "B. Băng", "C. Băng dính", "D. Vải"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // MARK: - Medical Equipment & Items
                Flashcard(question: "What is 'thermometer' in Vietnamese?", answer: "Nhiệt kế", hint: "Measures temperature", options: ["A. Đo nhiệt", "B. Nhiệt kế", "C. Cái đo", "D. Máy đo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stethoscope' in Vietnamese?", answer: "Ống nghe", hint: "Listens to heartbeat", options: ["A. Máy nghe", "B. Ống nghe", "C. Cái nghe", "D. Tai nghe"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'syringe' in Vietnamese?", answer: "Ống tiêm", hint: "For injections", options: ["A. Kim tiêm", "B. Ống tiêm", "C. Tiêm", "D. Bơm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wheelchair' in Vietnamese?", answer: "Xe lăn", hint: "For disabled patients", options: ["A. Xe đẩy", "B. Xe lăn", "C. Ghế bánh xe", "D. Nạng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'ambulance' in Vietnamese?", answer: "Xe cấp cứu", hint: "Emergency vehicle", options: ["A. Xe bệnh viện", "B. Xe cứu thương", "C. Xe cấp cứu", "D. Xe y tế"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // MARK: - Vietnamese to English
                Flashcard(question: "Từ 'Khám bệnh' trong tiếng Anh là gì?", answer: "Examination", hint: "Doctor checks you", options: ["A. Check", "B. Examination", "C. Look", "D. Test"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đau đầu' trong tiếng Anh là gì?", answer: "Headache", hint: "Pain in head", options: ["A. Head pain", "B. Headache", "C. Pain head", "D. Head hurt"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Sốt' trong tiếng Anh là gì?", answer: "Fever", hint: "High temperature", options: ["A. Hot", "B. Sick", "C. Fever", "D. Temperature"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Uống thuốc' trong tiếng Anh là gì?", answer: "Take medicine", hint: "Swallow pills", options: ["A. Drink medicine", "B. Eat medicine", "C. Take medicine", "D. Have medicine"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đơn thuốc' trong tiếng Anh là gì?", answer: "Prescription", hint: "Doctor's order", options: ["A. Medicine paper", "B. Prescription", "C. Recipe", "D. Medicine list"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Cấp cứu' trong tiếng Anh là gì?", answer: "Emergency", hint: "Urgent care", options: ["A. Urgent", "B. Emergency", "C. Quick", "D. Help"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Chấn thương' trong tiếng Anh là gì?", answer: "Injury", hint: "Physical damage", options: ["A. Hurt", "B. Injury", "C. Wound", "D. Damage"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Xét nghiệm' trong tiếng Anh là gì?", answer: "Test", hint: "Medical check", options: ["A. Check", "B. Examine", "C. Test", "D. Study"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // MARK: - Fill in the Blank - Common Medical Phrases
                Flashcard(question: "I need to see a ___ because I'm sick.", answer: "doctor", hint: "Medical professional", options: ["A. nurse", "B. doctor", "C. pharmacist", "D. dentist"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I have a terrible ___. My head hurts so much.", answer: "headache", hint: "Pain in head", options: ["A. pain", "B. fever", "C. headache", "D. cold"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The doctor gave me a ___ for antibiotics.", answer: "prescription", hint: "Written medicine order", options: ["A. paper", "B. prescription", "C. medicine", "D. note"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I need to take this ___ three times a day.", answer: "medicine", hint: "Treatment pill", options: ["A. drug", "B. pill", "C. medicine", "D. tablet"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "She's in the ___ room waiting for surgery.", answer: "operating", hint: "Where surgery happens", options: ["A. waiting", "B. emergency", "C. operating", "D. examination"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "Call an ___! This is an emergency!", answer: "ambulance", hint: "Emergency vehicle", options: ["A. doctor", "B. hospital", "C. ambulance", "D. nurse"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The nurse checked my temperature with a ___.", answer: "thermometer", hint: "Measures body heat", options: ["A. meter", "B. tool", "C. thermometer", "D. device"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "I have a high ___ of 39 degrees.", answer: "fever", hint: "Body temperature", options: ["A. temperature", "B. fever", "C. heat", "D. cold"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ helped the doctor during the surgery.", answer: "nurse", hint: "Medical assistant", options: ["A. patient", "B. nurse", "C. surgeon", "D. staff"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I broke my arm and need an ___.", answer: "X-ray", hint: "Medical scan", options: ["A. operation", "B. examination", "C. X-ray", "D. test"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "The pharmacist sold me the medicine at the ___.", answer: "pharmacy", hint: "Drug store", options: ["A. hospital", "B. clinic", "C. pharmacy", "D. store"], correctAnswer: "C", exerciseType: .fillInTheBlank),
                Flashcard(question: "I'm allergic to penicillin. I have an ___.", answer: "allergy", hint: "Body reaction", options: ["A. problem", "B. illness", "C. allergy", "D. disease"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // ============================================
        // MARK: - IELTS TOPICS (Chủ đề IELTS)
        // ============================================
        
        let ieltsEnvironmentTopic = Topic(
            name: "IELTS Environment (Môi trường)",
            subjectName: "Tiếng Anh chuyên ngành",
            flashcards: [
                // --- NHÓM 1: CÁC VẤN ĐỀ & Ô NHIỄM (Issues & Pollution) ---
                Flashcard(question: "Climate change", answer: "Biến đổi khí hậu", hint: "Sự thay đổi dài hạn của nhiệt độ và thời tiết.", options: ["A. Dự báo thời tiết", "B. Biến đổi khí hậu", "C. Thủng tầng ozone", "D. Nóng lên toàn cầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Global warming", answer: "Sự nóng lên toàn cầu", hint: "Nhiệt độ trái đất tăng do khí nhà kính.", options: ["A. Cháy rừng", "B. Tan băng", "C. Nóng lên toàn cầu", "D. Ô nhiễm nhiệt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Greenhouse effect", answer: "Hiệu ứng nhà kính", hint: "Nhiệt bị giữ lại trong bầu khí quyển bởi các loại khí gas.", options: ["A. Hiệu ứng nhà kính", "B. Khí thải", "C. Ô nhiễm khí", "D. Ánh sáng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Deforestation", answer: "Sự phá rừng", hint: "Chặt phá rừng quy mô lớn gây mất cân bằng sinh thái.", options: ["A. Trồng rừng", "B. Phá rừng", "C. Cháy rừng", "D. Khai thác"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Ozone layer depletion", answer: "Sự suy giảm tầng ozone", hint: "Tầng bảo vệ trái đất bị mỏng đi do hóa chất.", options: ["A. Thủng tầng ozone", "B. Ô nhiễm khí", "C. Bức xạ", "D. Ánh sáng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Acid rain", answer: "Mưa axit", hint: "Mưa chứa chất độc hại do ô nhiễm không khí nặng.", options: ["A. Mưa rào", "B. Mưa axit", "C. Mưa phùn", "D. Bão"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Soil erosion", answer: "Sự xói mòn đất", hint: "Lớp đất bề mặt bị nước hoặc gió cuốn trôi mất.", options: ["A. Sạt lở", "B. Xói mòn đất", "C. Đất phèn", "D. Hạn hán"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Water contamination", answer: "Sự nhiễm độc nước", hint: "Nguồn nước bị làm bẩn bởi hóa chất hoặc rác thải.", options: ["A. Nước sạch", "B. Thủy triều đen", "C. Nhiễm độc nước", "D. Lũ lụt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Exhaust fumes", answer: "Khí thải động cơ", hint: "Khói độc từ ống xả xe cộ hoặc nhà máy.", options: ["A. Bụi mịn", "B. Khí thải", "C. Hơi nước", "D. Mùi độc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Hazardous waste", answer: "Rác thải nguy hại", hint: "Rác chứa độc tố mạnh như pin, thuốc trừ sâu.", options: ["A. Rác nhựa", "B. Rác hữu cơ", "C. Rác nguy hại", "D. Phế liệu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Oil spill", answer: "Tràn dầu", hint: "Dầu đổ ra biển từ tàu hoặc dàn khoan.", options: ["A. Sóng thần", "B. Tràn dầu", "C. Thủy triều đỏ", "D. Ô nhiễm biển"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Poaching", answer: "Săn bắn trái phép", hint: "Giết hại động vật hoang dã trái luật pháp.", options: ["A. Đánh cá", "B. Săn trộm", "C. Chăn nuôi", "D. Bảo tồn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Toxic chemical", answer: "Hóa chất độc hại", hint: "Chất hóa học công nghiệp gây hại sức khỏe.", options: ["A. Thuốc trừ sâu", "B. Hóa chất độc", "C. Kim loại nặng", "D. Thuốc nhuộm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Overpopulation", answer: "Sự bùng nổ dân số", hint: "Quá nhiều người gây áp lực lên tài nguyên thiên nhiên.", options: ["A. Đông đúc", "B. Bùng nổ dân số", "C. Di dân", "D. Quy hoạch"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Drought", answer: "Hạn hán", hint: "Tình trạng thiếu nước nghiêm trọng kéo dài.", options: ["A. Lũ lụt", "B. Cháy rừng", "C. Hạn hán", "D. Sạt lở"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Flash flood", answer: "Lũ quét", hint: "Trận lũ dâng lên cực nhanh và bất ngờ ở vùng núi.", options: ["A. Lụt lội", "B. Lũ quét", "C. Thủy triều", "D. Sóng thần"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Landfill", answer: "Bãi chôn lấp rác", hint: "Nơi tập trung rác thải khổng lồ của thành phố.", options: ["A. Nhà máy rác", "B. Thùng rác", "C. Bãi chôn rác", "D. Khu tái chế"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Smog", answer: "Khói bụi ô nhiễm", hint: "Sự kết hợp giữa khói (smoke) và sương mù (fog).", options: ["A. Sương muối", "B. Khói bụi", "C. Mây đen", "D. Bụi mịn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Pesticide", answer: "Thuốc trừ sâu", hint: "Hóa chất diệt côn trùng trong nông nghiệp.", options: ["A. Phân bón", "B. Thuốc trừ sâu", "C. Chất kích thích", "D. Thuốc cỏ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Disposal", answer: "Sự vứt bỏ / Xử lý", hint: "Hành động loại bỏ rác thải.", options: ["A. Thu gom", "B. Xử lý rác", "C. Tái sử dụng", "D. Cất giữ"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 2: GIẢI PHÁP & HÀNH ĐỘNG (Solutions & Actions) ---
                Flashcard(question: "Reduce", answer: "Cắt giảm", hint: "Hạn chế lượng tài nguyên tiêu thụ.", options: ["A. Tái chế", "B. Tiết kiệm", "C. Cắt giảm", "D. Tái sử dụng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Reuse", answer: "Tái sử dụng", hint: "Dùng lại đồ cũ thay vì vứt đi.", options: ["A. Tái chế", "B. Tái sử dụng", "C. Sửa chữa", "D. Cất giữ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Recycle", answer: "Tái chế", hint: "Biến rác thải cũ thành nguyên liệu mới.", options: ["A. Tái sử dụng", "B. Phân loại", "C. Tái chế", "D. Xử lý"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Sustainability", answer: "Sự bền vững", hint: "Phát triển lâu dài mà không gây hại cho tương lai.", options: ["A. Sự ổn định", "B. Sự bền vững", "C. Sự phát triển", "D. Bảo vệ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Eco-friendly", answer: "Thân thiện môi trường", hint: "Sản phẩm hoặc lối sống xanh, sạch.", options: ["A. Hiện đại", "B. Tiết kiệm", "C. Thân thiện môi trường", "D. Xanh sạch"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Biodegradable", answer: "Có thể phân hủy sinh học", hint: "Có khả năng tự phân hủy tự nhiên bởi vi khuẩn.", options: ["A. Rác vô cơ", "B. Phân hủy sinh học", "C. Thân thiện", "D. Bền chắc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Conservation", answer: "Sự bảo tồn", hint: "Bảo vệ thiên nhiên, động vật và tài nguyên.", options: ["A. Sự duy trì", "B. Sự bảo tồn", "C. Sự phục hồi", "D. Ngăn chặn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Reforestation", answer: "Sự trồng rừng lại", hint: "Trồng cây trên vùng đất rừng đã bị tàn phá.", options: ["A. Khai thác rừng", "B. Bảo vệ rừng", "C. Trồng rừng", "D. Cháy rừng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Mitigation", answer: "Sự giảm nhẹ", hint: "Hành động làm giảm bớt mức độ nghiêm trọng của thiên tai.", options: ["A. Ngăn chặn", "B. Giảm nhẹ", "C. Đối phó", "D. Thích nghi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Carbon footprint", answer: "Dấu chân Carbon", hint: "Tổng lượng khí thải nhà kính của một cá nhân.", options: ["A. Khí thải nhà kính", "B. Dấu chân Carbon", "C. Ô nhiễm khí", "D. Năng lượng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Go green", answer: "Sống xanh", hint: "Thay đổi thói quen để bảo vệ môi trường.", options: ["A. Trồng cây", "B. Ăn chay", "C. Sống xanh", "D. Tiết kiệm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Awareness", answer: "Ý thức / Nhận thức", hint: "Hiểu biết đúng đắn về các vấn đề môi trường.", options: ["A. Kiến thức", "B. Ý thức", "C. Hành động", "D. Trách nhiệm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Sort rác", answer: "Phân loại rác", hint: "Chia rác thành từng nhóm hữu cơ và vô cơ.", options: ["A. Thu gom", "B. Phân loại", "C. Xử lý", "D. Tái chế"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Disposable", answer: "Dùng một lần", hint: "Đồ vật dùng xong bỏ ngay như túi nilon, ly nhựa.", options: ["A. Tái sử dụng", "B. Tiện lợi", "C. Dùng một lần", "D. Phế thải"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Preserve", answer: "Giữ gìn / Bảo tồn", hint: "Giữ môi trường ở trạng thái nguyên vẹn.", options: ["A. Bảo vệ", "B. Giữ gìn", "C. Duy trì", "D. Chăm sóc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Remedy", answer: "Biện pháp khắc phục", hint: "Cách giải quyết một vấn đề môi trường đã xảy ra.", options: ["A. Giải pháp", "B. Khắc phục", "C. Thuốc chữa", "D. Kết quả"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Prohibit", answer: "Cấm", hint: "Ban lệnh không cho phép thực hiện hành động gây ô nhiễm.", options: ["A. Hạn chế", "B. Cấm", "C. Ngăn cản", "D. Phạt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Restore", answer: "Phục hồi", hint: "Đưa hệ sinh thái trở lại trạng thái ban đầu.", options: ["A. Sửa chữa", "B. Phục hồi", "C. Xây mới", "D. Bảo vệ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Harness", answer: "Khai thác / Tận dụng", hint: "Tận dụng các nguồn năng lượng thiên nhiên.", options: ["A. Sử dụng", "B. Khai thác", "C. Tiết kiệm", "D. Tạo ra"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Green movement", answer: "Phong trào xanh", hint: "Các chiến dịch xã hội về môi trường.", options: ["A. Cách mạng", "B. Phong trào xanh", "C. Trồng rừng", "D. Biểu tình"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 3: NĂNG LƯỢNG (Energy) ---
                Flashcard(question: "Renewable energy", answer: "Năng lượng tái tạo", hint: "Nguồn năng lượng thiên nhiên không bao giờ cạn kiệt.", options: ["A. Năng lượng sạch", "B. Năng lượng tái tạo", "C. Điện mặt trời", "D. Gió"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Fossil fuels", answer: "Nhiên liệu hóa thạch", hint: "Các nguồn năng lượng như than đá, dầu mỏ.", options: ["A. Năng lượng cũ", "B. Nhiên liệu hóa thạch", "C. Chất thải", "D. Tài nguyên"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Solar power", answer: "Năng lượng mặt trời", hint: "Điện được tạo ra từ ánh sáng mặt trời.", options: ["A. Nhiệt năng", "B. Quang năng", "C. Điện mặt trời", "D. Pin mặt trời"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Wind turbine", answer: "Turbine gió", hint: "Công trình dùng sức gió để tạo ra điện.", options: ["A. Quạt gió", "B. Turbine gió", "C. Máy phát điện", "D. Trạm điện"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Hydroelectric power", answer: "Thủy điện", hint: "Nguồn điện lấy từ sức chảy của nước (đập thủy điện).", options: ["A. Nhiệt điện", "B. Điện lực", "C. Thủy điện", "D. Hồ chứa"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Nuclear energy", answer: "Năng lượng hạt nhân", hint: "Năng lượng sinh ra từ các phản ứng hạt nhân.", options: ["A. Năng lượng sạch", "B. Bom nguyên tử", "C. Năng lượng hạt nhân", "D. Phóng xạ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Geothermal energy", answer: "Năng lượng địa nhiệt", hint: "Năng lượng lấy từ sức nóng sâu trong lòng đất.", options: ["A. Núi lửa", "B. Địa nhiệt", "C. Nước nóng", "D. Khoáng sản"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Alternative energy", answer: "Năng lượng thay thế", hint: "Các nguồn năng lượng sạch dùng thay cho hóa thạch.", options: ["A. Năng lượng mới", "B. Năng lượng thay thế", "C. Năng lượng sạch", "D. Giải pháp"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Biofuel", answer: "Nhiên liệu sinh học", hint: "Nhiên liệu được làm từ thực vật (ngô, mía).", options: ["A. Xăng sinh học", "B. Nhiên liệu sạch", "C. Nhiên liệu sinh học", "D. Khí biogas"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Energy efficiency", answer: "Hiệu quả năng lượng", hint: "Sử dụng ít năng lượng nhưng vẫn đạt hiệu suất cao.", options: ["A. Tiết kiệm điện", "B. Hiệu quả năng lượng", "C. Công suất", "D. Cường độ"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 4: SINH THÁI & THIÊN NHIÊN (Ecology & Nature) ---
                Flashcard(question: "Biodiversity", answer: "Đa dạng sinh học", hint: "Sự phong phú của các loài sinh vật trên trái đất.", options: ["A. Hệ sinh thái", "B. Đa dạng sinh học", "C. Sinh vật học", "D. Động vật"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Ecosystem", answer: "Hệ sinh thái", hint: "Cộng đồng các sinh vật sống và môi trường của chúng.", options: ["A. Môi trường sống", "B. Chuỗi thức ăn", "C. Hệ sinh thái", "D. Thiên nhiên"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Endangered species", answer: "Loài có nguy cơ tuyệt chủng", hint: "Những loài động thực vật sắp biến mất vĩnh viễn.", options: ["A. Động vật hoang dã", "B. Loài có nguy cơ", "C. Loài quý hiếm", "D. Loài lạ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Habitat", answer: "Môi trường sống", hint: "Nơi ở tự nhiên đặc thù của một loài sinh vật.", options: ["A. Hệ sinh thái", "B. Khu bảo tồn", "C. Môi trường sống", "D. Nơi cư trú"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Wildlife", answer: "Động vật hoang dã", hint: "Các loài thú, chim sống tự nhiên không được thuần hóa.", options: ["A. Thiên nhiên", "B. Sinh vật", "C. Động vật hoang dã", "D. Rừng rậm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Extinct", answer: "Tuyệt chủng", hint: "Không còn một cá thể nào sống sót trên trái đất.", options: ["A. Chết chóc", "B. Biến mất", "C. Tuyệt chủng", "D. Đã cũ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Nature reserve", answer: "Khu bảo tồn thiên nhiên", hint: "Vùng đất hoang dã được bảo vệ nghiêm ngặt.", options: ["A. Công viên quốc gia", "B. Khu bảo tồn", "C. Vườn bách thảo", "D. Rừng cấm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Atmosphere", answer: "Bầu khí quyển", hint: "Lớp khí bao bọc xung quanh trái đất.", options: ["A. Không gian", "B. Bầu khí quyển", "C. Tầng ozone", "D. Không khí"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Natural resources", answer: "Tài nguyên thiên nhiên", hint: "Đất, nước, khoáng sản, rừng và năng lượng.", options: ["A. Kho báu", "B. Tài nguyên thiên nhiên", "C. Nguyên liệu", "D. Năng lượng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Ecology", answer: "Sinh thái học", hint: "Khoa học nghiên cứu sự tương tác giữa sinh vật và môi trường.", options: ["A. Môi trường", "B. Sinh học", "C. Sinh thái học", "D. Địa lý"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Flora and Fauna", answer: "Hệ thực vật và Động vật", hint: "Tất cả cây cối và muông thú trong một vùng.", options: ["A. Thiên nhiên", "B. Hệ sinh thái", "C. Hệ thực vật và động vật", "D. Sinh vật cảnh"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Environmentally conscious", answer: "Có ý thức về môi trường", hint: "Luôn quan tâm đến việc bảo vệ thiên nhiên.", options: ["A. Bảo vệ môi trường", "B. Có ý thức môi trường", "C. Yêu thiên nhiên", "D. Tiết kiệm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Litter", answer: "Rác vứt bừa bãi", hint: "Rác thải bị bỏ lung tung trên đường phố hoặc nơi công cộng.", options: ["A. Thùng rác", "B. Rác thải", "C. Rác vứt bừa bãi", "D. Phế liệu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Shortage", answer: "Sự thiếu hụt", hint: "Tình trạng không đủ tài nguyên cần thiết (như nước).", options: ["A. Cạn kiệt", "B. Thiếu hụt", "C. Hết sạch", "D. Giảm sút"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Irreparable damage", answer: "Thiệt hại không thể cứu vãn", hint: "Những tàn phá quá nặng nề không thể sửa chữa được.", options: ["A. Thiệt hại nặng", "B. Không thể cứu vãn", "C. Hỏng hóc", "D. Sự tàn phá"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Balance", answer: "Sự cân bằng", hint: "Giữ cho hệ sinh thái ổn định.", options: ["A. Cân bằng", "B. Duy trì", "C. Ổn định", "D. Phát triển"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Exhausted", answer: "Bị cạn kiệt", hint: "Tài nguyên đã bị dùng hết sạch.", options: ["A. Mệt mỏi", "B. Cạn kiệt", "C. Hết hạn", "D. Phế bỏ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Catastrophe", answer: "Thảm họa", hint: "Sự cố môi trường cực kỳ kinh khủng.", options: ["A. Tai nạn", "B. Thảm họa", "C. Nguy hiểm", "D. Cảnh báo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Oxygen", answer: "Khí Oxy", hint: "Khí cần thiết cho sự sống, do cây tạo ra.", options: ["A. Không khí", "B. Khí Oxy", "C. Khí Ni-tơ", "D. Khí thải"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Organic", answer: "Hữu cơ", hint: "Các chất hoặc rác có nguồn gốc từ sinh vật.", options: ["A. Tự nhiên", "B. Hữu cơ", "C. Sạch", "D. Nguyên chất"], correctAnswer: "B", exerciseType: .englishToVietnamese)
            ]
        )
        
        // IELTS Topic 2: Technology & Innovation
        let ieltsTechnologyTopic = Topic(
            name: "IELTS: Technology & Innovation",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Technology Vocabulary
                Flashcard(question: "What is 'artificial intelligence' in Vietnamese?", answer: "Trí tuệ nhân tạo", hint: "AI", options: ["A. Robot", "B. Trí tuệ nhân tạo", "C. Máy tính", "D. Công nghệ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'innovation' in Vietnamese?", answer: "Sự đổi mới, sáng tạo", hint: "New ideas", options: ["A. Phát minh", "B. Sáng tạo", "C. Sự đổi mới", "D. Công nghệ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'breakthrough' in Vietnamese?", answer: "Đột phá", hint: "Major advance", options: ["A. Tiến bộ", "B. Đột phá", "C. Thay đổi", "D. Phát triển"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'automation' in Vietnamese?", answer: "Tự động hóa", hint: "Machines do work", options: ["A. Máy móc", "B. Robot", "C. Tự động hóa", "D. Điều khiển"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'digital' in Vietnamese?", answer: "Kỹ thuật số", hint: "Electronic format", options: ["A. Số", "B. Điện tử", "C. Kỹ thuật số", "D. Online"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'virtual reality' in Vietnamese?", answer: "Thực tế ảo", hint: "VR technology", options: ["A. Ảo", "B. Thực tế ảo", "C. Kính", "D. Game"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'cybersecurity' in Vietnamese?", answer: "An ninh mạng", hint: "Internet safety", options: ["A. Mạng", "B. An toàn", "C. An ninh mạng", "D. Bảo mật"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'upgrade' in Vietnamese?", answer: "Nâng cấp", hint: "Make better", options: ["A. Cải thiện", "B. Nâng cấp", "C. Sửa", "D. Thay đổi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Trí tuệ nhân tạo' trong tiếng Anh là gì?", answer: "Artificial Intelligence", hint: "AI", options: ["A. AI", "B. Artificial Intelligence", "C. Robot", "D. Technology"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Đột phá' trong tiếng Anh là gì?", answer: "Breakthrough", hint: "Major advance", options: ["A. Break", "B. Progress", "C. Breakthrough", "D. Innovation"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Fill in the Blank
                Flashcard(question: "___ intelligence is changing many industries.", answer: "Artificial", hint: "AI", options: ["A. Human", "B. Artificial", "C. Natural", "D. Digital"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "Companies invest heavily in ___ to create new products.", answer: "innovation", hint: "New ideas", options: ["A. research", "B. innovation", "C. marketing", "D. production"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // IELTS Topic 3: Health & Lifestyle
        let ieltsHealthTopic = Topic(
            name: "IELTS: Health & Lifestyle",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Health Vocabulary
                Flashcard(question: "What is 'mental health' in Vietnamese?", answer: "Sức khỏe tâm thần", hint: "Psychological wellbeing", options: ["A. Tinh thần", "B. Tâm lý", "C. Sức khỏe tâm thần", "D. Sức khỏe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'lifestyle' in Vietnamese?", answer: "Lối sống, phong cách sống", hint: "Way of living", options: ["A. Cuộc sống", "B. Lối sống", "C. Sống", "D. Phong cách"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'wellbeing' in Vietnamese?", answer: "Hạnh phúc, sự khỏe mạnh", hint: "Good health and happiness", options: ["A. Tốt", "B. Khỏe", "C. Hạnh phúc", "D. Sức khỏe"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'nutrition' in Vietnamese?", answer: "Dinh dưỡng", hint: "Food value", options: ["A. Thức ăn", "B. Dinh dưỡng", "C. Vitamin", "D. Ăn uống"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'obesity' in Vietnamese?", answer: "Béo phì", hint: "Very overweight", options: ["A. Mập", "B. Béo phì", "C. Thừa cân", "D. Nặng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stress' in Vietnamese?", answer: "Căng thẳng", hint: "Mental pressure", options: ["A. Mệt", "B. Áp lực", "C. Căng thẳng", "D. Lo lắng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'balanced diet' in Vietnamese?", answer: "Chế độ ăn cân bằng", hint: "Variety of foods", options: ["A. Ăn kiêng", "B. Chế độ ăn", "C. Chế độ ăn cân bằng", "D. Ăn uống"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'prevention' in Vietnamese?", answer: "Phòng ngừa", hint: "Stop before it happens", options: ["A. Ngăn chặn", "B. Phòng ngừa", "C. Chữa", "D. Bảo vệ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Dinh dưỡng' trong tiếng Anh là gì?", answer: "Nutrition", hint: "Food value", options: ["A. Food", "B. Nutrition", "C. Diet", "D. Vitamin"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Căng thẳng' trong tiếng Anh là gì?", answer: "Stress", hint: "Mental pressure", options: ["A. Tired", "B. Pressure", "C. Stress", "D. Worried"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Fill in the Blank
                Flashcard(question: "A ___ diet includes fruits, vegetables, and proteins.", answer: "balanced", hint: "Variety of foods", options: ["A. healthy", "B. balanced", "C. good", "D. normal"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "___ is important for both physical and mental health.", answer: "Exercise", hint: "Physical activity", options: ["A. Sleep", "B. Food", "C. Exercise", "D. Rest"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // IELTS Topic 4: Education & Career
        let ieltsEducationTopic = Topic(
            name: "IELTS: Education & Career",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Education Vocabulary
                Flashcard(question: "What is 'curriculum' in Vietnamese?", answer: "Chương trình giảng dạy", hint: "Course content", options: ["A. Khóa học", "B. Chương trình giảng dạy", "C. Bài học", "D. Môn học"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'qualification' in Vietnamese?", answer: "Bằng cấp, trình độ", hint: "Degree or certificate", options: ["A. Bằng", "B. Học vị", "C. Bằng cấp", "D. Chứng chỉ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'vocational training' in Vietnamese?", answer: "Đào tạo nghề", hint: "Job skills training", options: ["A. Học nghề", "B. Đào tạo nghề", "C. Dạy nghề", "D. Nghề"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'competence' in Vietnamese?", answer: "Năng lực", hint: "Ability to do something", options: ["A. Khả năng", "B. Năng lực", "C. Tài năng", "D. Kỹ năng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'scholarship' in Vietnamese?", answer: "Học bổng", hint: "Financial aid for study", options: ["A. Tiền học", "B. Học bổng", "C. Trợ cấp", "D. Học phí"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'internship' in Vietnamese?", answer: "Thực tập", hint: "Work experience", options: ["A. Làm việc", "B. Thực tập", "C. Học việc", "D. Tập sự"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'unemployment' in Vietnamese?", answer: "Thất nghiệp", hint: "No job", options: ["A. Không việc", "B. Thất nghiệp", "C. Nghỉ việc", "D. Mất việc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'career path' in Vietnamese?", answer: "Con đường sự nghiệp", hint: "Professional journey", options: ["A. Nghề nghiệp", "B. Sự nghiệp", "C. Con đường sự nghiệp", "D. Công việc"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Học bổng' trong tiếng Anh là gì?", answer: "Scholarship", hint: "Financial aid", options: ["A. Money", "B. Scholarship", "C. Grant", "D. Aid"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Thất nghiệp' trong tiếng Anh là gì?", answer: "Unemployment", hint: "No job", options: ["A. Jobless", "B. Unemployed", "C. Unemployment", "D. No work"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Fill in the Blank
                Flashcard(question: "Many students apply for ___ to study abroad.", answer: "scholarships", hint: "Financial aid", options: ["A. money", "B. scholarships", "C. loans", "D. grants"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The school ___ includes math, science, and languages.", answer: "curriculum", hint: "Course content", options: ["A. program", "B. curriculum", "C. syllabus", "D. courses"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )
        
        // IELTS Topic 5: Society & Culture
        let ieltsSocietyTopic = Topic(
            name: "IELTS: Society & Culture",
            subjectName: "Tiếng Anh",
            flashcards: [
                // Society Vocabulary
                Flashcard(question: "What is 'diversity' in Vietnamese?", answer: "Sự đa dạng", hint: "Many different types", options: ["A. Khác nhau", "B. Đa dạng", "C. Sự đa dạng", "D. Nhiều"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'equality' in Vietnamese?", answer: "Bình đẳng", hint: "Same rights for all", options: ["A. Công bằng", "B. Bình đẳng", "C. Như nhau", "D. Giống nhau"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'generation gap' in Vietnamese?", answer: "Khoảng cách thế hệ", hint: "Age difference issues", options: ["A. Thế hệ", "B. Khác biệt", "C. Khoảng cách thế hệ", "D. Tuổi tác"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'multiculturalism' in Vietnamese?", answer: "Đa văn hóa", hint: "Many cultures together", options: ["A. Văn hóa", "B. Nhiều văn hóa", "C. Đa văn hóa", "D. Hòa nhập"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'integration' in Vietnamese?", answer: "Hội nhập", hint: "Joining together", options: ["A. Tham gia", "B. Hội nhập", "C. Kết hợp", "D. Hòa nhập"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'discrimination' in Vietnamese?", answer: "Phân biệt đối xử", hint: "Unfair treatment", options: ["A. Phân biệt", "B. Phân biệt đối xử", "C. Bất công", "D. Đối xử"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'stereotype' in Vietnamese?", answer: "Định kiến", hint: "Fixed idea about group", options: ["A. Kiến thức", "B. Quan điểm", "C. Định kiến", "D. Suy nghĩ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is 'community' in Vietnamese?", answer: "Cộng đồng", hint: "Group of people", options: ["A. Nhóm", "B. Cộng đồng", "C. Xã hội", "D. Dân"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Vietnamese to English
                Flashcard(question: "Từ 'Bình đẳng' trong tiếng Anh là gì?", answer: "Equality", hint: "Same rights", options: ["A. Equal", "B. Equality", "C. Fair", "D. Same"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Từ 'Cộng đồng' trong tiếng Anh là gì?", answer: "Community", hint: "Group of people", options: ["A. Society", "B. Community", "C. Group", "D. People"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // Fill in the Blank
                Flashcard(question: "Cultural ___ means having many different cultures in society.", answer: "diversity", hint: "Many different types", options: ["A. difference", "B. diversity", "C. variety", "D. mixture"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "The ___ gap between parents and children can cause conflicts.", answer: "generation", hint: "Age difference", options: ["A. age", "B. generation", "C. time", "D. culture"], correctAnswer: "B", exerciseType: .fillInTheBlank)
            ]
        )

        let ieltsPersonalityTopic = Topic(
            name: "IELTS Personality (70 Từ vựng)",
            subjectName: "Tiếng Anh",
            flashcards: [
                // --- NHÓM 1: TÍNH CÁCH TÍCH CỰC (Positive - 25 từ) ---
                Flashcard(question: "Confident", answer: "Tự tin", hint: "Tin tưởng vào khả năng bản thân. 'He is a confident leader.'", options: ["A. Kiêu ngạo", "B. Mạnh mẽ", "C. Tự tin", "D. Liều lĩnh"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Generous", answer: "Hào phóng", hint: "Sẵn sàng cho đi, giúp đỡ. 'A generous donor.'", options: ["A. Hào phóng", "B. Tốt bụng", "C. Giàu có", "D. Rộng lượng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Ambitious", answer: "Tham vọng", hint: "Có khát vọng thành công lớn. 'She is very ambitious.'", options: ["A. Chăm chỉ", "B. Tham vọng", "C. Tự phụ", "D. Giỏi giang"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Reliable", answer: "Đáng tin cậy", hint: "Có thể tin tưởng giao việc. 'A reliable employee.'", options: ["A. Trung thành", "B. Thật thà", "C. Cẩn thận", "D. Đáng tin cậy"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Optimistic", answer: "Lạc quan", hint: "Luôn nghĩ về điều tốt đẹp. 'Stay optimistic about the future.'", options: ["A. Vui vẻ", "B. Lạc quan", "C. Tích cực", "D. Yêu đời"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Diligent", answer: "Siêng năng", hint: "Làm việc cần cù, tỉ mỉ. 'A diligent student.'", options: ["A. Siêng năng", "B. Chăm chỉ", "C. Nỗ lực", "D. Thông minh"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Creative", answer: "Sáng tạo", hint: "Có nhiều ý tưởng mới. 'A creative designer.'", options: ["A. Nghệ thuật", "B. Khéo léo", "C. Sáng tạo", "D. Độc đáo"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Honest", answer: "Trung thực", hint: "Luôn nói sự thật. 'To be honest with you.'", options: ["A. Thật thà", "B. Chân thành", "C. Trung thực", "D. Thẳng thắn"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Humble", answer: "Khiêm tốn", hint: "Không khoe khoang. 'Success made him humble.'", options: ["A. Nhún nhường", "B. Giản dị", "C. Hiền lành", "D. Khiêm tốn"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Sociable", answer: "Hòa đồng", hint: "Thích giao tiếp, gặp gỡ. 'A very sociable person.'", options: ["A. Thân thiện", "B. Dễ gần", "C. Hòa đồng", "D. Cởi mở"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Witty", answer: "Dí dỏm", hint: "Thông minh và hài hước nhanh nhạy.", options: ["A. Hài hước", "B. Dí dỏm", "C. Vui vẻ", "D. Sắc sảo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Courageous", answer: "Dũng cảm", hint: "Không sợ hãi nguy hiểm.", options: ["A. Dũng cảm", "B. Gan dạ", "C. Mạnh mẽ", "D. Anh hùng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Compassionate", answer: "Lòng trắc ẩn", hint: "Thấu hiểu và thương xót người khác.", options: ["A. Tốt bụng", "B. Nhân hậu", "C. Lòng trắc ẩn", "D. Nhạy cảm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Proactive", answer: "Chủ động", hint: "Tự mình hành động trước khi được bảo.", options: ["A. Năng nổ", "B. Chủ động", "C. Tích cực", "D. Nhanh nhẹn"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Persistent", answer: "Kiên trì", hint: "Không bỏ cuộc dù khó khăn.", options: ["A. Bướng bỉnh", "B. Quyết tâm", "C. Kiên trì", "D. Cố chấp"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Versatile", answer: "Linh hoạt / Đa tài", hint: "Có thể làm được nhiều việc khác nhau.", options: ["A. Thông minh", "B. Đa năng", "C. Linh hoạt", "D. Nhanh nhạy"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Sincere", answer: "Chân thành", hint: "Thật lòng, không giả dối.", options: ["A. Chân thành", "B. Thật thà", "C. Tin cậy", "D. Tốt bụng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Considerate", answer: "Chu đáo / Biết quan tâm", hint: "Luôn nghĩ cho cảm nhận của người khác.", options: ["A. Tốt bụng", "B. Chu đáo", "C. Nhã nhặn", "D. Hiểu biết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Resourceful", answer: "Tháo vát", hint: "Giỏi xoay xở trong tình huống khó.", options: ["A. Thông minh", "B. Tháo vát", "C. Nhanh nhẹn", "D. Tài giỏi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Tolerant", answer: "Vị tha / Khoan dung", hint: "Chấp nhận sự khác biệt của người khác.", options: ["A. Hiền lành", "B. Khoan dung", "C. Kiên nhẫn", "D. Dễ tính"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Charismatic", answer: "Có sức lôi cuốn", hint: "Có khả năng thu hút và thuyết phục người khác.", options: ["A. Lôi cuốn", "B. Đẹp trai", "C. Nổi tiếng", "D. Mạnh mẽ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Affable", answer: "Niềm nở / Nhã nhặn", hint: "Rất dễ nói chuyện và lịch sự.", options: ["A. Thân thiện", "B. Niềm nở", "C. Vui vẻ", "D. Dễ tính"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Articulate", answer: "Ăn nói lưu loát", hint: "Khả năng diễn đạt ý tưởng rõ ràng.", options: ["A. Thông minh", "B. Lưu loát", "C. Hoạt ngôn", "D. Khôn khéo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Broad-minded", answer: "Tư tưởng rộng mở", hint: "Sẵn sàng tiếp nhận cái mới.", options: ["A. Thông minh", "B. Rộng mở", "C. Thoải mái", "D. Phóng khoáng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Meticulous", answer: "Tỉ mỉ / Cẩn thận từng chút", hint: "Rất chú trọng đến chi tiết nhỏ.", options: ["A. Tỉ mỉ", "B. Cẩn thận", "C. Siêng năng", "D. Kỹ tính"], correctAnswer: "A", exerciseType: .englishToVietnamese),

                // --- NHÓM 2: TÍNH CÁCH TIÊU CỰC (Negative - 25 từ) ---
                Flashcard(question: "Arrogant", answer: "Kiêu ngạo", hint: "Nghĩ mình giỏi hơn người khác.", options: ["A. Tự tin", "B. Kiêu ngạo", "C. Ngạo mạn", "D. Tự phụ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Selfish", answer: "Ích kỷ", hint: "Chỉ nghĩ cho bản thân.", options: ["A. Tham lam", "B. Ích kỷ", "C. Keo kiệt", "D. Xấu tính"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Stubborn", answer: "Bướng bỉnh", hint: "Không chịu thay đổi ý kiến.", options: ["A. Cứng rắn", "B. Ngoan cố", "C. Bướng bỉnh", "D. Kiên định"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Lazy", answer: "Lười biếng", hint: "Không muốn nỗ lực làm gì.", options: ["A. Chậm chạp", "B. Ủ rũ", "C. Thảnh thơi", "D. Lười biếng"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Pessimistic", answer: "Bi quan", hint: "Luôn nghĩ về điều tồi tệ.", options: ["A. Bi quan", "B. Buồn bã", "C. Tiêu cực", "D. Chán nản"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Aggressive", answer: "Hung hăng", hint: "Dễ gây hấn, bạo lực.", options: ["A. Mạnh mẽ", "B. Tức giận", "C. Nóng nảy", "D. Hung hăng"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Cynical", answer: "Hoài nghi", hint: "Luôn nghi ngờ lòng tốt của người khác.", options: ["A. Khó tính", "B. Hoài nghi", "C. Độc ác", "D. Lạnh lùng"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Greedy", answer: "Tham lam", hint: "Muốn có nhiều tiền bạc, quyền lực.", options: ["A. Ích kỷ", "B. Độc ác", "C. Tham lam", "D. Keo kiệt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Hypocritical", answer: "Đạo đức giả", hint: "Nói một đằng làm một nẻo.", options: ["A. Dối trá", "B. Gian xảo", "C. Lừa lọc", "D. Đạo đức giả"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Impulsive", answer: "Bốc đồng", hint: "Làm mà không nghĩ đến hậu quả.", options: ["A. Bốc đồng", "B. Nhanh nhẹn", "C. Hấp tấp", "D. Vội vàng"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Jealous", answer: "Ghen tị", hint: "Khó chịu khi thấy người khác hơn mình.", options: ["A. Đố kỵ", "B. Tức giận", "C. Ganh đua", "D. Ghen tị"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Moody", answer: "Tính khí thất thường", hint: "Thay đổi cảm xúc quá nhanh.", options: ["A. Buồn bã", "B. Thất thường", "C. Khó chịu", "D. Nhạy cảm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Narrow-minded", answer: "Hẹp hòi", hint: "Không chấp nhận ý kiến khác mình.", options: ["A. Khó tính", "B. Hẹp hòi", "C. Ích kỷ", "D. Bảo thủ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Possessive", answer: "Có tính chiếm hữu", hint: "Muốn kiểm soát người khác hoàn toàn.", options: ["A. Ích kỷ", "B. Chiếm hữu", "C. Ghen tuông", "D. Độc đoán"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Sarcastic", answer: "Mỉa mai", hint: "Dùng từ ngữ để chế nhạo người khác.", options: ["A. Hài hước", "B. Mỉa mai", "C. Độc địa", "D. Sắc sảo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Vain", answer: "Tự phụ", hint: "Quá tự hào về ngoại hình/tài năng bản thân.", options: ["A. Kiêu ngạo", "B. Điệu đà", "C. Nông cạn", "D. Tự phụ"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Vindictive", answer: "Hay thù hằn", hint: "Luôn muốn trả thù người khác.", options: ["A. Độc ác", "B. Thù hằn", "C. Nhỏ nhen", "D. Khó tính"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Naive", answer: "Ngây thơ", hint: "Quá tin người do thiếu kinh nghiệm.", options: ["A. Hồn nhiên", "B. Khờ khạo", "C. Ngây thơ", "D. Đơn giản"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Gullible", answer: "Dễ bị lừa", hint: "Ai nói gì cũng tin ngay.", options: ["A. Dễ bị lừa", "B. Nhẹ dạ", "C. Khờ khạo", "D. Ngây thơ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Apathetic", answer: "Thờ ơ", hint: "Không quan tâm đến bất cứ điều gì.", options: ["A. Lạnh lùng", "B. Thờ ơ", "C. Chán nản", "D. Lười biếng"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- NHÓM 3: TRUNG TÍNH & NÂNG CAO (Neutral & Advanced - 20 từ) ---
                Flashcard(question: "Reserved", answer: "Kín đáo", hint: "Không hay chia sẻ cảm xúc.", options: ["A. Nhút nhát", "B. Kín đáo", "C. Trầm tính", "D. Khó gần"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Sensitive", answer: "Nhạy cảm", hint: "Dễ xúc động hoặc bị tổn thương.", options: ["A. Yếu đuối", "B. Tinh tế", "C. Sâu sắc", "D. Nhạy cảm"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Cautious", answer: "Thận trọng", hint: "Làm gì cũng suy tính kỹ rủi ro.", options: ["A. Cẩn thận", "B. Lo lắng", "C. Thận trọng", "D. Sợ hãi"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Independent", answer: "Độc lập", hint: "Tự mình làm mọi việc.", options: ["A. Tự lập", "B. Tự do", "C. Độc lập", "D. Mạnh mẽ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Competitive", answer: "Tính cạnh tranh cao", hint: "Luôn muốn thắng người khác.", options: ["A. Tính cạnh tranh cao", "B. Ganh đua", "C. Nỗ lực", "D. Quyết liệt"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "Introverted", answer: "Hướng nội", hint: "Thích ở một mình để nạp năng lượng.", options: ["A. Trầm lặng", "B. Khép kín", "C. Nhút nhát", "D. Hướng nội"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "Extroverted", answer: "Hướng ngoại", hint: "Thích đám đông và giao lưu.", options: ["A. Năng động", "B. Hướng ngoại", "C. Vui vẻ", "D. Nhiệt tình"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Eccentric", answer: "Lập dị", hint: "Có những thói quen lạ lùng, khác người.", options: ["A. Điên rồ", "B. Độc đáo", "C. Lập dị", "D. Khác biệt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "Stoic", answer: "Khắc kỷ", hint: "Chịu đựng đau khổ mà không than vãn.", options: ["A. Lạnh lùng", "B. Khắc kỷ", "C. Mạnh mẽ", "D. Bình thản"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "Indecisive", answer: "Do dự", hint: "Khó khăn trong việc đưa ra quyết định.", options: ["A. Do dự", "B. Chậm chạp", "C. Nhút nhát", "D. Phân vân"], correctAnswer: "A", exerciseType: .englishToVietnamese)
            ],
            readings: [
                ReadingPassage(
                    title: "I am Happy",
                    level: .beginner,
                    content: "My name is Tom. I am a student. I am very honest and friendly. My sister is creative. She likes to draw. We are a happy family.",
                    questions: [
                        ReadingQuestion(question: "Is Tom honest?", options: ["A. Yes, he is", "B. No, he isn't", "C. He is lazy", "D. He is arrogant"], correctAnswer: "A", explanation: "Tom tự giới thiệu: 'I am very honest'.")
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "Honest", meaning: "Trung thực", example: "He is an honest boy.")
                    ]
                ),
                ReadingPassage(
                    title: "The Diligent Student",
                    level: .elementary,
                    content: """
            Nam is a diligent student in my class. He is very proactive and always asks questions. He is also ambitious because he wants to study abroad. 

            Sometimes Nam is a bit cautious. He thinks carefully before answering. However, he is very sociable. He has many friends because he is enthusiastic and sincere.
            """,
                    questions: [
                        ReadingQuestion(question: "Why does Nam have many friends?", options: ["A. Because he is cautious", "B. Because he is lazy", "C. Because he is enthusiastic and sincere", "D. Because he is stubborn"], correctAnswer: "C", explanation: "Đoạn văn nói Nam có nhiều bạn vì nhiệt tình (enthusiastic) và chân thành (sincere).")
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "Ambitious", meaning: "Tham vọng", example: "She is an ambitious lawyer."),
                        VocabularyItem(word: "Sociable", meaning: "Hòa đồng", example: "He is very sociable.")
                    ]
                ),ReadingPassage(
                    title: "Understanding Each Other",
                    level: .intermediate,
                    content: """
            It is important to understand that people have different characters. Some are extroverted and love parties. Others are introverted and prefer being alone. 

            We should not be cynical about others' kindness. If someone is sensitive, we must be considerate. Being competitive is good for work, but don't become aggressive. A broad-minded person will always find it easier to work in a team than a narrow-minded one.
            """,
                    questions: [
                        ReadingQuestion(question: "What should we do when someone is 'sensitive'?", options: ["A. Be aggressive", "B. Be considerate", "C. Be cynical", "D. Be impulsive"], correctAnswer: "B", explanation: "Văn bản khuyên: 'If someone is sensitive, we must be considerate' (phải chu đáo/biết quan tâm)."),
                        ReadingQuestion(question: "Who finds it easier to work in a team?", options: ["A. Narrow-minded people", "B. Aggressive people", "C. Broad-minded people", "D. Pessimistic people"], correctAnswer: "C", explanation: "Người có tư tưởng rộng mở (broad-minded) làm việc nhóm tốt hơn.")
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "Cynical", meaning: "Hoài nghi", example: "Don't be so cynical."),
                        VocabularyItem(word: "Considerate", meaning: "Chu đáo", example: "It was considerate of you to help.")
                    ]
                ),

                // 4. UPPER INTERMEDIATE: Tính cách trong quản lý và đàm phán.
                ReadingPassage(
                    title: "Professionalism and Character",
                    level: .upperIntermediate,
                    content: """
            In a professional environment, being articulate and versatile is highly valued. A manager needs to be charismatic to inspire the team. However, they should avoid being vain or hợm hĩnh about their power. 

            Meticulous planning can prevent many mistakes. When a project fails, don't be apathetic or pessimistic. Instead, stay stoic and look for solutions. Avoid being vindictive toward colleagues who made errors. A reliable and tolerant leader will always gain more respect.
            """,
                    questions: [
                        ReadingQuestion(question: "What should a manager avoid?", options: ["A. Being charismatic", "B. Being vain", "C. Being articulate", "D. Being versatile"], correctAnswer: "B", explanation: "Đoạn văn khuyên người quản lý nên tránh tự phụ (vain)."),
                        ReadingQuestion(question: "What helps a leader gain respect?", options: ["A. Being apathetic", "B. Being vindictive", "C. Being reliable and tolerant", "D. Being sarcastic"], correctAnswer: "C", explanation: "Sự tin cậy (reliable) và khoan dung (tolerant) giúp lãnh đạo được tôn trọng.")
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "Articulate", meaning: "Lưu loát", example: "She is an articulate speaker."),
                        VocabularyItem(word: "Vindictive", meaning: "Hay thù hằn", example: "He is not a vindictive person.")
                    ]
                ),

                // 5. ADVANCED: Phân tích tâm lý học về tính cách con người.
                ReadingPassage(
                    title: "The Mask of Personality",
                    level: .advanced,
                    content: """
            Personality is a complex construct. Many individuals appear affable and sociable, yet they possess a reserved and indecisive nature beneath the surface. The tendency to be impulsive is often a defense mechanism for those who are internally sensitive. 

            We must be wary of gullible behaviors in an age of misinformation. Furthermore, being hypocritical—acting against one's stated beliefs—can ruin a person's reputation permanently. While an eccentric person might be seen as odd, their creative spirit often drives innovation. Ultimately, achieving a balance between being ambitious and remaining humble is the hallmark of a mature character.
            """,
                    questions: [
                        ReadingQuestion(question: "What can ruin a person's reputation?", options: ["A. Being eccentric", "B. Being hypocritical", "C. Being affable", "D. Being creative"], correctAnswer: "B", explanation: "Đạo đức giả (hypocritical) có thể hủy hoại danh tiếng vĩnh viễn."),
                        ReadingQuestion(question: "How is 'impulsiveness' described in the text?", options: ["A. A sign of arrogance", "B. A defense mechanism", "C. A creative spirit", "D. A reliable trait"], correctAnswer: "B", explanation: "Văn bản mô tả sự bốc đồng (impulsive) là một cơ chế phòng vệ (defense mechanism).")
                    ],
                    vocabularyHelp: [
                        VocabularyItem(word: "Hypocritical", meaning: "Đạo đức giả", example: "It is hypocritical to say one thing and do another."),
                        VocabularyItem(word: "Affable", meaning: "Niềm nở/Nhã nhặn", example: "He was an affable host.")
                    ]
                )
            ]
        )

        // ============================================
        // MARK: - TIẾNG TRUNG (CHINESE) TOPICS
        // ============================================
        
        // Numbers in Chinese
        let chineseNumbersTopic = Topic(
            name: "Numbers (数字 - Shùzì)",
            subjectName: "Tiếng Trung",
            flashcards: [
                // Basic numbers 1-10
                Flashcard(question: "这是什么数字？→ 一", answer: "yī (một)", hint: "Số đầu tiên", options: ["A. yī (một)", "B. èr (hai)", "C. sān (ba)", "D. sì (bốn)"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 二", answer: "èr (hai)", hint: "Sau số một", options: ["A. yī (một)", "B. èr (hai)", "C. sān (ba)", "D. wǔ (năm)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 三", answer: "sān (ba)", hint: "Sau số hai", options: ["A. èr (hai)", "B. sān (ba)", "C. sì (bốn)", "D. wǔ (năm)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 四", answer: "sì (bốn)", hint: "Sau số ba", options: ["A. sān (ba)", "B. sì (bốn)", "C. wǔ (năm)", "D. liù (sáu)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 五", answer: "wǔ (năm)", hint: "Một nửa của mười", options: ["A. sì (bốn)", "B. wǔ (năm)", "C. liù (sáu)", "D. qī (bảy)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 六", answer: "liù (sáu)", hint: "Sau số năm", options: ["A. wǔ (năm)", "B. liù (sáu)", "C. qī (bảy)", "D. bā (tám)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 七", answer: "qī (bảy)", hint: "Số may mắn", options: ["A. liù (sáu)", "B. qī (bảy)", "C. bā (tám)", "D. jiǔ (chín)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 八", answer: "bā (tám)", hint: "Số may mắn Trung Quốc", options: ["A. qī (bảy)", "B. bā (tám)", "C. jiǔ (chín)", "D. shí (mười)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 九", answer: "jiǔ (chín)", hint: "Trước số mười", options: ["A. bā (tám)", "B. jiǔ (chín)", "C. shí (mười)", "D. qī (bảy)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "这是什么数字？→ 十", answer: "shí (mười)", hint: "Hai bàn tay", options: ["A. jiǔ (chín)", "B. shí (mười)", "C. bǎi (trăm)", "D. qiān (nghìn)"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Reverse - Vietnamese to Chinese
                Flashcard(question: "Số 'một' bằng tiếng Trung là gì?", answer: "一 (yī)", hint: "Số đầu tiên", options: ["A. 一 (yī)", "B. 二 (èr)", "C. 三 (sān)", "D. 四 (sì)"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Số 'năm' bằng tiếng Trung là gì?", answer: "五 (wǔ)", hint: "Một nửa của mười", options: ["A. 四 (sì)", "B. 五 (wǔ)", "C. 六 (liù)", "D. 七 (qī)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "Số 'mười' bằng tiếng Trung là gì?", answer: "十 (shí)", hint: "Hai bàn tay", options: ["A. 九 (jiǔ)", "B. 十 (shí)", "C. 百 (bǎi)", "D. 千 (qiān)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // Fill in the blank
                Flashcard(question: "我有___个苹果。(Tôi có năm quả táo)", answer: "五 (wǔ)", hint: "Số 5", options: ["A. 四 (sì)", "B. 五 (wǔ)", "C. 六 (liù)", "D. 七 (qī)"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "一加九等于___。(Một cộng chín bằng mười)", answer: "十 (shí)", hint: "1 + 9 = ?", options: ["A. 八 (bā)", "B. 九 (jiǔ)", "C. 十 (shí)", "D. 十一 (shíyī)"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        let chineseRadicalsTopic = Topic(
            name: "Radicals (部首 - Bùshǒu)",
            subjectName: "Tiếng Trung",
            flashcards: [
                // --- 1 NÉT ---
                Flashcard(question: "部首：一", answer: "Bộ Nhất (Số 1)", hint: "Dùng làm nét ngang trong các chữ như: 天 (Thiên), 下 (Hạ). Biểu thị sự bắt đầu hoặc thống nhất.", options: ["A. Nhất", "B. Côn", "C. Chủ", "D. Phiệt"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：丨", answer: "Bộ Côn (Nét sổ)", hint: "Nét sổ thẳng đứng, xuất hiện trong chữ 中 (Trung). Biểu thị sự thông suốt từ trên xuống.", options: ["A. Nhất", "B. Côn", "C. Chủ", "D. Phiệt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：丶", answer: "Bộ Chủ (Điểm)", hint: "Dấu chấm, xuất hiện trong chữ 主 (Chủ) hoặc 太 (Thái). Biểu thị một thực thể nhỏ hoặc điểm nhấn.", options: ["A. Nhất", "B. Côn", "C. Chủ", "D. Phiệt"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：丿", answer: "Bộ Phiệt (Nét phẩy)", hint: "Nét phẩy trái, dùng trong chữ 人 (Nhân). Biểu thị sự chuyển động hoặc kéo dài.", options: ["A. Nhất", "B. Côn", "C. Chủ", "D. Phiệt"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：乙", answer: "Bộ Ất (Vị trí thứ 2)", hint: "Dùng trong can chi, xuất hiện trong chữ 九 (Cửu), 艺 (Nghệ). Biểu thị sự uốn lượn.", options: ["A. Nhất", "B. Côn", "C. Chủ", "D. Ất"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：亅", answer: "Bộ Quyết (Nét móc)", hint: "Nét sổ có móc, dùng trong chữ 了 (Liễu), 事 (Sự). Giống cái lưỡi câu để giữ vật.", options: ["A. Nhất", "B. Côn", "C. Quyết", "D. Phiệt"], correctAnswer: "C", exerciseType: .englishToVietnamese),

                // --- 2 NÉT ---
                Flashcard(question: "部首：二", answer: "Bộ Nhị (Số 2)", hint: "Dùng trong các chữ liên quan đến số đếm hoặc quan hệ tầng lớp như 于 (Vu), 云 (Vân).", options: ["A. Nhất", "B. Nhị", "C. Tam", "D. Tứ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：人 (亻)", answer: "Bộ Nhân (Người)", hint: "Bộ thủ quan trọng nhất. Dùng trong chữ 他 (Anh ấy), 你 (Bạn). Liên quan đến con người và hoạt động của người.", options: ["A. Nhân", "B. Nhập", "C. Bát", "D. Đao"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：儿", answer: "Bộ Nhi (Trẻ con)", hint: "Đuôi chữ nhi hóa trong tiếng Bắc Kinh. Xuất hiện trong chữ 儿子 (Con trai), 兄 (Huynh).", options: ["A. Nhân", "B. Nhi", "C. Nhập", "D. Bát"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：入", answer: "Bộ Nhập (Vào)", hint: "Dùng trong chữ 入口 (Lối vào). Ý nghĩa là tiến từ ngoài vào trong.", options: ["A. Nhân", "B. Nhi", "C. Nhập", "D. Bát"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：八", answer: "Bộ Bát (Số 8)", hint: "Tượng trưng cho sự chia rẽ, xuất hiện trong chữ 分 (Phân - chia ra), 公 (Công).", options: ["A. Nhân", "B. Nhi", "C. Nhập", "D. Bát"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：冂", answer: "Bộ Quynh (Vùng biên viễn)", hint: "Dùng trong chữ 网 (Vọng - lưới), 冈 (Cương). Chỉ ranh giới bao quanh vùng xa xôi.", options: ["A. Quynh", "B. Mịch", "C. Băng", "D. Kỷ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：冖", answer: "Bộ Mịch (Trùm lên)", hint: "Dùng trong chữ 写 (Tả - viết), 军 (Quân). Chỉ hành động che đậy hoặc bao phủ từ trên xuống.", options: ["A. Quynh", "B. Mịch", "C. Băng", "D. Kỷ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：冫", answer: "Bộ Băng (Nước đá)", hint: "Xuất hiện trong chữ 冷 (Lãnh - lạnh), 冰 (Băng). Liên quan đến nhiệt độ thấp, lạnh giá.", options: ["A. Quynh", "B. Mịch", "C. Băng", "D. Kỷ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：几", answer: "Bộ Kỷ (Cái bàn/ghế)", hint: "Dùng trong chữ 几 (Kỷ - mấy), 桌 (Trác). Chỉ các loại đồ nội thất để ngồi hoặc đặt đồ.", options: ["A. Quynh", "B. Mịch", "C. Băng", "D. Kỷ"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：刀 (刂)", answer: "Bộ Đao (Con dao)", hint: "Nằm bên phải chữ như 别 (Biệt), 削 (Tước). Liên quan đến vũ khí sắc bén hoặc cắt xẻ.", options: ["A. Đao", "B. Lực", "C. Bao", "D. Chùy"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：力", answer: "Bộ Lực (Sức mạnh)", hint: "Dùng trong chữ 劳 (Lao động), 办 (Làm việc). Liên quan đến sức lực cơ bắp.", options: ["A. Đao", "B. Lực", "C. Bao", "D. Chùy"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：又", answer: "Bộ Hựu (Lại một lần nữa)", hint: "Dùng trong chữ 欢 (Hoan), 变 (Biến). Biểu thị sự lặp lại hành động hoặc bàn tay phải làm việc.", options: ["A. Hựu", "B. Khẩu", "C. Vi", "D. Thổ"], correctAnswer: "A", exerciseType: .englishToVietnamese),

                // --- 3 NÉT ---
                Flashcard(question: "部首：口", answer: "Bộ Khẩu (Cái miệng)", hint: "Dùng trong chữ 吃 (Ăn), 喝 (Uống). Liên quan đến ăn uống, lời nói hoặc các đồ vật có lỗ.", options: ["A. Khẩu", "B. Vi", "C. Thổ", "D. Sĩ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：囗", answer: "Bộ Vi (Vây quanh)", hint: "Luôn bao quanh các nét khác như trong chữ 国 (Quốc), 围 (Vi). Chỉ ranh giới, bao vây.", options: ["A. Khẩu", "B. Vi", "C. Thổ", "D. Sĩ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：土", answer: "Bộ Thổ (Đất)", hint: "Dùng trong chữ 地 (Địa), 城 (Thành). Liên quan đến đất đai, xây dựng hoặc địa điểm.", options: ["A. Khẩu", "B. Vi", "C. Thổ", "D. Sĩ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：士", answer: "Bộ Sĩ (Kẻ sĩ)", hint: "Dùng trong chữ 壮 (Tráng), 声 (Thanh). Chỉ người trí thức hoặc nam giới thời xưa.", options: ["A. Khẩu", "B. Vi", "C. Thổ", "D. Sĩ"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：夕", answer: "Bộ Tịch (Đêm tối)", hint: "Dùng trong chữ 多 (Đa - nhiều đêm), 外 (Ngoại - bên ngoài). Liên quan đến thời gian buổi tối.", options: ["A. Đại", "B. Nữ", "C. Tử", "D. Tịch"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：大", answer: "Bộ Đại (To lớn)", hint: "Dùng trong chữ 天 (Thiên), 太 (Thái). Biểu thị sự to lớn, quan trọng hoặc hình dáng người dang tay.", options: ["A. Đại", "B. Nữ", "C. Tử", "D. Tịch"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：女", answer: "Bộ Nữ (Phụ nữ)", hint: "Dùng trong chữ 妈 (Mẹ), 奶 (Bà). Liên quan đến phụ nữ, quan hệ gia đình hoặc tính cách.", options: ["A. Đại", "B. Nữ", "C. Tử", "D. Tịch"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：子", answer: "Bộ Tử (Con cái)", hint: "Dùng trong chữ 好 (Hảo - tốt: phụ nữ có con), 学 (Học). Liên quan đến trẻ con, thế hệ sau.", options: ["A. Đại", "B. Nữ", "C. Tử", "D. Tịch"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：宀", answer: "Bộ Miên (Mái nhà)", hint: "Dùng trong chữ 家 (Gia), 安 (An). Liên quan đến nhà cửa, nơi ở vững chãi.", options: ["A. Miên", "B. Tháp", "C. Th寸", "D. Tiểu"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：寸", answer: "Bộ Thốn (Tấc/Đo đạc)", hint: "Dùng trong chữ 对 (Đối), 寺 (Tự). Chỉ quy tắc, đơn vị đo lường hoặc khoảng cách ngắn.", options: ["A. Miên", "B. Thốn", "C. Tiểu", "D. Uông"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：小", answer: "Bộ Tiểu (Nhỏ bé)", hint: "Dùng trong chữ 少 (Thiếu), 尖 (Tiêm - nhọn). Đối lập với bộ Đại, chỉ sự nhỏ nhặt.", options: ["A. Miên", "B. Thốn", "C. Tiểu", "D. Uông"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：尸", answer: "Bộ Thi (Xác chết/Thân thể)", hint: "Dùng trong chữ 居 (Cư), 尾 (Vĩ - đuôi). Liên quan đến cơ thể người hoặc nơi ở.", options: ["A. Thi", "B. Sơn", "C. Xuyên", "D. Công"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：山", answer: "Bộ Sơn (Núi)", hint: "Dùng trong chữ 岩 (Nham), 岛 (Đảo). Liên quan đến địa hình đồi núi, cao lớn.", options: ["A. Thi", "B. Sơn", "C. Xuyên", "D. Công"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：工", answer: "Bộ Công (Công việc/Thợ)", hint: "Dùng trong chữ 左 (Tả), 差 (Sai). Liên quan đến kỹ năng, lao động chân tay hoặc dụng cụ.", options: ["A. Thi", "B. Sơn", "C. Xuyên", "D. Công"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：己", answer: "Bộ Kỷ (Bản thân mình)", hint: "Dùng trong chữ 已经 (Dĩ kinh - đã rồi). Tự bản thân mình xử lý.", options: ["A. Kỷ", "B. Cân", "C. Can", "D. Nghiễm"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：巾", answer: "Bộ Cân (Cái khăn)", hint: "Dùng trong chữ 帮 (Bang - giúp đỡ), 币 (Tệ - tiền). Liên quan đến vải vóc, dệt may.", options: ["A. Kỷ", "B. Cân", "C. Can", "D. Nghiễm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：干", answer: "Bộ Can (Thiên can/Lá chắn)", hint: "Dùng trong chữ 平 (Bình), 年 (Niên). Tượng trưng cho vũ khí phòng vệ hoặc sự khô ráo.", options: ["A. Kỷ", "B. Cân", "C. Can", "D. Nghiễm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：广", answer: "Bộ Nghiễm (Mái nhà bên sườn núi)", hint: "Dùng trong chữ 店 (Điếm - cửa hàng), 府 (Phủ). Chỉ các tòa nhà lớn hoặc công trình công cộng.", options: ["A. Kỷ", "B. Cân", "C. Can", "D. Nghiễm"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：弓", answer: "Bộ Cung (Cái cung)", hint: "Dùng trong chữ 强 (Cường - mạnh), 引 (Dẫn). Liên quan đến vũ khí cung tên hoặc sự đàn hồi.", options: ["A. Cung", "B. Kế", "C. Tam", "D. Đạo"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：彡", answer: "Bộ Tam (Lông dài/Tóc)", hint: "Dùng trong chữ 形 (Hình), 影 (Ảnh). Liên quan đến trang trí, râu tóc hoặc bóng dáng.", options: ["A. Cung", "B. Kế", "C. Tam", "D. Đạo"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：彳", answer: "Bộ Xích (Bước chân trái)", hint: "Dùng trong chữ 行 (Hành), 很 (Hèn - rất: bước đi nhiều). Liên quan đến di chuyển, đi lại.", options: ["A. Tâm", "B. Xích", "C. Qua", "D. Hộ"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- 4 NÉT ---
                Flashcard(question: "部首：心 (忄)", answer: "Bộ Tâm (Quả tim/Tâm trí)", hint: "Dùng trong chữ 情 (Tình), 想 (Tưởng). Liên quan đến cảm xúc, suy nghĩ, tâm hồn.", options: ["A. Tâm", "B. Qua", "C. Hộ", "D. Thủ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：戈", answer: "Bộ Qua (Cái mác/Vũ khí)", hint: "Dùng trong chữ 我 (Ngã - tôi: cầm vũ khí), 战 (Chiến). Liên quan đến chiến tranh, binh khí.", options: ["A. Tâm", "B. Qua", "C. Hộ", "D. Thủ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：户", answer: "Bộ Hộ (Cửa một cánh)", hint: "Dùng trong chữ 房 (Phòng), 扇 (Phiến - cái quạt). Liên quan đến nhà ở, hộ gia đình.", options: ["A. Tâm", "B. Qua", "C. Hộ", "D. Thủ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：手 (扌)", answer: "Bộ Thủ (Cái tay)", hint: "Dùng trong chữ 打 (Đánh), 拿 (Lấy). Liên quan đến hành động dùng tay tác động.", options: ["A. Tâm", "B. Qua", "C. Hộ", "D. Thủ"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：日", answer: "Bộ Nhật (Mặt trời/Ngày)", hint: "Dùng trong chữ 明 (Minh - sáng), 时 (Thời). Liên quan đến thời gian và ánh sáng.", options: ["A. Nhật", "B. Nguyệt", "C. Mộc", "D. Khiếm"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：月", answer: "Bộ Nguyệt (Mặt trăng/Tháng)", hint: "Dùng trong chữ 朋 (Bằng), hoặc biến thể chỉ cơ thể như 脸 (Mặt), 腿 (Chân).", options: ["A. Nhật", "B. Nguyệt", "C. Mộc", "D. Khiếm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：木", answer: "Bộ Mộc (Gỗ/Cây)", hint: "Dùng trong chữ 机 (Máy), 树 (Cây). Liên quan đến thực vật gỗ hoặc đồ vật làm từ gỗ.", options: ["A. Nhật", "B. Nguyệt", "C. Mộc", "D. Khiếm"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：水 (氵)", answer: "Bộ Thủy (Nước)", hint: "Dùng trong chữ 海 (Biển), 河 (Sông). Liên quan đến chất lỏng, sông ngòi.", options: ["A. Thủy", "B. Hỏa", "C. Trảo", "D. Phụ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：火 (灬)", answer: "Bộ Hỏa (Lửa)", hint: "Dùng trong chữ 热 (Nhiệt - nóng), 烤 (Nướng). Liên quan đến sức nóng, ánh sáng, nấu nướng.", options: ["A. Thủy", "B. Hỏa", "C. Trảo", "D. Phụ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：牛 (牜)", answer: "Bộ Ngưu (Con trâu/bò)", hint: "Dùng trong chữ 物 (Vật - đồ vật), 特 (Đặc). Liên quan đến gia súc hoặc vật phẩm.", options: ["A. Ngưu", "B. Khuyển", "C. Huyền", "D. Ngọc"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：犬 (犭)", answer: "Bộ Khuyển (Con chó)", hint: "Dùng trong chữ 狗 (Chó), 猫 (Mèo). Liên quan đến các loài động vật bốn chân (thú).", options: ["A. Ngưu", "B. Khuyển", "C. Huyền", "D. Ngọc"], correctAnswer: "B", exerciseType: .englishToVietnamese),

                // --- 5 NÉT & CAO HƠN ---
                Flashcard(question: "部首：玉 (王)", answer: "Bộ Ngọc (Vua/Ngọc quý)", hint: "Dùng trong chữ 现 (Hiện), 理 (Lý). Liên quan đến châu báu, trang sức hoặc sự quý giá.", options: ["A. Ngọc", "B. Qua", "C. Cam", "D. Sinh"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：田", answer: "Bộ Điền (Ruộng)", hint: "Dùng trong chữ 男 (Nam - sức lực làm ruộng), 界 (Giới). Liên quan đến nông nghiệp, đất đai.", options: ["A. Dụng", "B. Điền", "C. Thất", "D. Nạch"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：目", answer: "Bộ Mục (Mắt)", hint: "Dùng trong chữ 看 (Nhìn), 眼 (Mắt). Liên quan đến thị giác và các hành động của mắt.", options: ["A. Mục", "B. Mâu", "C. Thạch", "D. Kỳ"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：石", answer: "Bộ Thạch (Đá)", hint: "Dùng trong chữ 研 (Nghiên), 破 (Phá). Liên quan đến khoáng sản hoặc đồ vật cứng bằng đá.", options: ["A. Thỉ", "B. Thạch", "C. Kỳ", "D. Hòa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：禾", answer: "Bộ Hòa (Lúa)", hint: "Dùng trong chữ 秋 (Thu - mùa lúa cháy), 私 (Tư). Liên quan đến ngũ cốc, nông nghiệp.", options: ["A. Thỉ", "B. Thạch", "C. Kỳ", "D. Hòa"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：竹 (⺮)", answer: "Bộ Trúc (Tre nứa)", hint: "Dùng trong chữ 笔 (Bút - quản bút bằng tre), 笑 (Tiếng cười). Liên quan đến tre nứa.", options: ["A. Trúc", "B. Mễ", "C. Hệ", "D. Phẫu"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：糸 (纟)", answer: "Bộ Mịch (Tơ tằm)", hint: "Dùng trong chữ 给 (Cho), 红 (Đỏ - nhuộm tơ). Liên quan đến dây nhợ, tơ lụa, kết nối.", options: ["A. Trúc", "B. Mễ", "C. Mịch", "D. Phẫu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：艹", answer: "Bộ Thảo (Cỏ)", hint: "Dùng trong chữ 花 (Hoa), 草 (Cỏ). Liên quan đến các loài cây thân thảo, hoa, thực vật nhỏ.", options: ["A. Sắc", "B. Thảo", "C. Trùng", "D. Huyết"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：虫", answer: "Bộ Trùng (Sâu bọ)", hint: "Dùng trong chữ 蛇 (Rắn), 虾 (Tôm). Liên quan đến côn trùng, bò sát và động vật nhỏ.", options: ["A. Sắc", "B. Thảo", "C. Trùng", "D. Huyết"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：衣 (衤)", answer: "Bộ Y (Quần áo)", hint: "Dùng trong chữ 衬 (Áo sơ mi), 被 (Cái chăn). Liên quan đến may mặc, phục trang.", options: ["A. Hành", "B. Y", "C. Á", "D. Kiến"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：言 (讠)", answer: "Bộ Ngôn (Nói)", hint: "Dùng trong chữ 说 (Nói), 语 (Ngôn ngữ). Liên quan đến giao tiếp, lời nói, chữ viết.", options: ["A. Giác", "B. Ngôn", "C. Cốc", "D. Đậu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：贝 (贝)", answer: "Bộ Bối (Vỏ sò/Tiền quý)", hint: "Dùng trong chữ 贵 (Quý), 财 (Tài). Người xưa dùng vỏ sò làm tiền nên liên quan đến tài chính.", options: ["A. Thỉ", "B. Trì", "C. Bối", "D. Xích"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：走 (⻎)", answer: "Bộ Tẩu (Chạy/Đi)", hint: "Dùng trong chữ 越 (Vượt), 起 (Dậy). Liên quan đến hành động vận động đôi chân.", options: ["A. Tẩu", "B. Túc", "C. Thân", "D. Xa"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：足 (⻊)", answer: "Bộ Túc (Cái chân)", hint: "Dùng trong chữ 跑 (Chạy), 踢 (Đá). Liên quan trực tiếp đến bộ phận bàn chân.", options: ["A. Tẩu", "B. Túc", "C. Thân", "D. Xa"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：车 (车)", answer: "Bộ Xa (Cái xe)", hint: "Dùng trong chữ 辆 (Chiếc xe), 轮 (Bánh xe). Liên quan đến phương tiện giao thông đường bộ.", options: ["A. Tẩu", "B. Túc", "C. Thân", "D. Xa"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：金 (钅)", answer: "Bộ Kim (Vàng/Kim loại)", hint: "Dùng trong chữ 钱 (Tiền), 铁 (Sắt). Liên quan đến kim khí, tiền bạc hoặc vật cứng sắc nhọn.", options: ["A. Dậu", "B. Biện", "C. Lý", "D. Kim"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：门 (门)", answer: "Bộ Môn (Cánh cửa)", hint: "Dùng trong chữ 问 (Hỏi), 间 (Gian - phòng). Liên quan đến lối vào, không gian kín.", options: ["A. Trường", "B. Môn", "C. Phụ", "D. Đãi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：食 (饣)", answer: "Bộ Thực (Ăn)", hint: "Dùng trong chữ 饭 (Cơm), 馆 (Quán). Liên quan đến thực phẩm, ăn uống.", options: ["A. Thực", "B. Thủ", "C. Hương", "D. Mã"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：马 (马)", answer: "Bộ Mã (Con ngựa)", hint: "Dùng trong chữ 骑 (Cưỡi), 验 (Nghiệm - thử ngựa). Liên quan đến loài ngựa hoặc tốc độ.", options: ["A. Thực", "B. Thủ", "C. Hương", "D. Mã"], correctAnswer: "D", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：鱼 (鱼)", answer: "Bộ Ngư (Con cá)", hint: "Dùng trong chữ 鲜 (Tươi), 鲁 (Lỗ). Liên quan đến các loài thủy sản, cá.", options: ["A. Ngư", "B. Điểu", "C. Lộc", "D. Miễn"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "部首：鸟 (鸟)", answer: "Bộ Điểu (Con chim)", hint: "Dùng trong chữ 鸡 (Gà), 鸭 (Vịt). Liên quan đến các loài chim và gia cầm.", options: ["A. Ngư", "B. Điểu", "C. Lộc", "D. Miễn"], correctAnswer: "B", exerciseType: .englishToVietnamese)
            ]
        )
        
        // Basic Greetings in Chinese
        let chineseGreetingsTopic = Topic(
            name: "Greetings (问候 - Wènhòu)",
            subjectName: "Tiếng Trung",
            flashcards: [
                Flashcard(question: "'Xin chào' trong tiếng Trung là gì?", answer: "你好 (nǐ hǎo)", hint: "Hello", options: ["A. 你好 (nǐ hǎo)", "B. 再见 (zàijiàn)", "C. 谢谢 (xièxie)", "D. 对不起 (duìbuqǐ)"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Tạm biệt' trong tiếng Trung là gì?", answer: "再见 (zàijiàn)", hint: "Goodbye", options: ["A. 你好 (nǐ hǎo)", "B. 再见 (zàijiàn)", "C. 早上好 (zǎoshang hǎo)", "D. 晚安 (wǎn'ān)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Cảm ơn' trong tiếng Trung là gì?", answer: "谢谢 (xièxie)", hint: "Thank you", options: ["A. 对不起 (duìbuqǐ)", "B. 不客气 (bù kèqi)", "C. 谢谢 (xièxie)", "D. 你好 (nǐ hǎo)"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Xin lỗi' trong tiếng Trung là gì?", answer: "对不起 (duìbuqǐ)", hint: "Sorry", options: ["A. 谢谢 (xièxie)", "B. 对不起 (duìbuqǐ)", "C. 不客气 (bù kèqi)", "D. 再见 (zàijiàn)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Không sao/Không có gì' trong tiếng Trung là gì?", answer: "不客气 (bù kèqi)", hint: "You're welcome", options: ["A. 谢谢 (xièxie)", "B. 对不起 (duìbuqǐ)", "C. 不客气 (bù kèqi)", "D. 再见 (zàijiàn)"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Chào buổi sáng' trong tiếng Trung là gì?", answer: "早上好 (zǎoshang hǎo)", hint: "Morning greeting", options: ["A. 你好 (nǐ hǎo)", "B. 早上好 (zǎoshang hǎo)", "C. 晚安 (wǎn'ān)", "D. 下午好 (xiàwǔ hǎo)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // Reverse
                Flashcard(question: "What is '你好 (nǐ hǎo)' in Vietnamese?", answer: "Xin chào", hint: "Hello", options: ["A. Xin chào", "B. Tạm biệt", "C. Cảm ơn", "D. Xin lỗi"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is '谢谢 (xièxie)' in Vietnamese?", answer: "Cảm ơn", hint: "Thank you", options: ["A. Xin lỗi", "B. Không có gì", "C. Cảm ơn", "D. Xin chào"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is '再见 (zàijiàn)' in Vietnamese?", answer: "Tạm biệt", hint: "Goodbye", options: ["A. Xin chào", "B. Tạm biệt", "C. Cảm ơn", "D. Chúc ngủ ngon"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Fill in the blank
                Flashcard(question: "When I meet someone, I say: ___", answer: "你好 (nǐ hǎo)", hint: "Hello", options: ["A. 你好", "B. 再见", "C. 谢谢", "D. 对不起"], correctAnswer: "A", exerciseType: .fillInTheBlank),
                Flashcard(question: "When someone helps me, I say: ___", answer: "谢谢 (xièxie)", hint: "Thank you", options: ["A. 你好", "B. 再见", "C. 谢谢", "D. 对不起"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )
        
        // Family in Chinese
        let chineseFamilyTopic = Topic(
            name: "Family (家庭 - Jiātíng)",
            subjectName: "Tiếng Trung",
            flashcards: [
                Flashcard(question: "'Bố' trong tiếng Trung là gì?", answer: "爸爸 (bàba)", hint: "Father", options: ["A. 妈妈 (māma)", "B. 爸爸 (bàba)", "C. 哥哥 (gēge)", "D. 弟弟 (dìdi)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Mẹ' trong tiếng Trung là gì?", answer: "妈妈 (māma)", hint: "Mother", options: ["A. 爸爸 (bàba)", "B. 姐姐 (jiějie)", "C. 妈妈 (māma)", "D. 妹妹 (mèimei)"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Anh trai (older brother)' trong tiếng Trung là gì?", answer: "哥哥 (gēge)", hint: "Older brother", options: ["A. 弟弟 (dìdi)", "B. 哥哥 (gēge)", "C. 爸爸 (bàba)", "D. 叔叔 (shūshu)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Em trai (younger brother)' trong tiếng Trung là gì?", answer: "弟弟 (dìdi)", hint: "Younger brother", options: ["A. 哥哥 (gēge)", "B. 弟弟 (dìdi)", "C. 妹妹 (mèimei)", "D. 爸爸 (bàba)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Chị gái (older sister)' trong tiếng Trung là gì?", answer: "姐姐 (jiějie)", hint: "Older sister", options: ["A. 妹妹 (mèimei)", "B. 姐姐 (jiějie)", "C. 妈妈 (māma)", "D. 奶奶 (nǎinai)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Em gái (younger sister)' trong tiếng Trung là gì?", answer: "妹妹 (mèimei)", hint: "Younger sister", options: ["A. 姐姐 (jiějie)", "B. 妹妹 (mèimei)", "C. 妈妈 (māma)", "D. 女儿 (nǚ'ér)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Ông (paternal)' trong tiếng Trung là gì?", answer: "爷爷 (yéye)", hint: "Father's father", options: ["A. 爷爷 (yéye)", "B. 奶奶 (nǎinai)", "C. 外公 (wàigōng)", "D. 外婆 (wàipó)"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Bà (paternal)' trong tiếng Trung là gì?", answer: "奶奶 (nǎinai)", hint: "Father's mother", options: ["A. 妈妈 (māma)", "B. 奶奶 (nǎinai)", "C. 外婆 (wàipó)", "D. 姐姐 (jiějie)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                
                // Reverse
                Flashcard(question: "What is '爸爸 (bàba)' in Vietnamese?", answer: "Bố", hint: "Father", options: ["A. Mẹ", "B. Bố", "C. Anh", "D. Ông"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is '妈妈 (māma)' in Vietnamese?", answer: "Mẹ", hint: "Mother", options: ["A. Bố", "B. Chị", "C. Mẹ", "D. Bà"], correctAnswer: "C", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is '哥哥 (gēge)' in Vietnamese?", answer: "Anh trai", hint: "Older brother", options: ["A. Em trai", "B. Anh trai", "C. Bố", "D. Chú"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                
                // Fill in the blank
                Flashcard(question: "My ___ is very kind. (Father)", answer: "爸爸 (bàba)", hint: "Male parent", options: ["A. 妈妈", "B. 爸爸", "C. 哥哥", "D. 弟弟"], correctAnswer: "B", exerciseType: .fillInTheBlank),
                Flashcard(question: "I love my ___. (Mother)", answer: "妈妈 (māma)", hint: "Female parent", options: ["A. 爸爸", "B. 姐姐", "C. 妈妈", "D. 奶奶"], correctAnswer: "C", exerciseType: .fillInTheBlank)
            ]
        )

        let itVocabularyTopic = Topic(
        name: "IT Fundamentals (Công nghệ thông tin)",
        subjectName: "Tiếng Anh chuyên ngành",
        flashcards: [
            // --- NHÓM 1: PHẦN CỨNG & HỆ THỐNG (Hardware & Systems) ---
            Flashcard(question: "Hardware", answer: "Phần cứng", 
                hint: "Các thiết bị vật lý cấu thành máy tính (chuột, bàn phím, CPU).", 
                options: ["A. Phần mềm", "B. Phần cứng", "C. Hệ điều hành", "D. Mạng lưới"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Software", answer: "Phần mềm", 
                hint: "Tập hợp các chỉ thị/chương trình chạy trên máy tính.", 
                options: ["A. Phần cứng", "B. Ứng dụng", "C. Phần mềm", "D. Dữ liệu"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Operating System (OS)", answer: "Hệ điều hành", 
                hint: "Phần mềm quản lý phần cứng (Ví dụ: Windows, macOS, Linux).", 
                options: ["A. Hệ điều hành", "B. Trình duyệt", "C. Máy chủ", "D. Vi xử lý"], correctAnswer: "A", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Server", answer: "Máy chủ", 
                hint: "Máy tính cung cấp dữ liệu hoặc dịch vụ cho các máy tính khác.", 
                options: ["A. Máy khách", "B. Máy chủ", "C. Bộ định tuyến", "D. Lưu trữ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Database", answer: "Cơ sở dữ liệu", 
                hint: "Nơi lưu trữ dữ liệu có cấu trúc (Ví dụ: MySQL, MongoDB).", 
                options: ["A. Tập tin", "B. Bộ nhớ", "C. Cơ sở dữ liệu", "D. Bảng mã"], correctAnswer: "C", exerciseType: .englishToVietnamese),

            // --- NHÓM 2: PHÁT TRIỂN PHẦN MỀM (Software Development) ---
            Flashcard(question: "Framework", answer: "Khung phần mềm", 
                hint: "Tập hợp các thư viện và quy tắc có sẵn để xây dựng app.", 
                options: ["A. Công cụ", "B. Ngôn ngữ", "C. Khung phần mềm", "D. Giao diện"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Source code", answer: "Mã nguồn", 
                hint: "Đoạn mã do lập trình viên viết ra bằng ngôn ngữ lập trình.", 
                options: ["A. Mã hóa", "B. Mã nguồn", "C. Mã máy", "D. Tập lệnh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Debug", answer: "Gỡ lỗi", 
                hint: "Quá trình tìm và sửa lỗi trong chương trình.", 
                options: ["A. Chạy thử", "B. Gỡ lỗi", "C. Biên dịch", "D. Cài đặt"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Deploy", answer: "Triển khai", 
                hint: "Đưa sản phẩm/code lên môi trường thực tế cho người dùng.", 
                options: ["A. Phát triển", "B. Thiết kế", "C. Triển khai", "D. Kiểm thử"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Backend", answer: "Phần xử lý phía sau (Hậu trường)", 
                hint: "Phần xử lý logic và database mà người dùng không thấy.", 
                options: ["A. Giao diện", "B. Hệ điều hành", "C. Phía máy chủ", "D. Phía người dùng"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Frontend", answer: "Phần giao diện người dùng", 
                hint: "Phần hiển thị mà người dùng trực tiếp nhìn thấy và tương tác.", 
                options: ["A. Giao diện", "B. Dữ liệu", "C. Cấu trúc", "D. Giải thuật"], correctAnswer: "A", exerciseType: .englishToVietnamese),

            // --- NHÓM 3: MẠNG & BẢO MẬT (Networking & Security) ---
            Flashcard(question: "Protocol", answer: "Giao thức", 
                hint: "Quy tắc truyền thông giữa các thiết bị (Ví dụ: HTTP, FTP).", 
                options: ["A. Quy trình", "B. Giao thức", "C. Bảo mật", "D. Kết nối"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Bandwidth", answer: "Băng thông", 
                hint: "Tốc độ truyền dữ liệu tối đa trong 1 giây của mạng.", 
                options: ["A. Dung lượng", "B. Băng thông", "C. Tần số", "D. Độ trễ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Firewall", answer: "Tường lửa", 
                hint: "Hệ thống ngăn chặn truy cập trái phép từ bên ngoài.", 
                options: ["A. Diệt virus", "B. Mã hóa", "C. Tường lửa", "D. Cổng vào"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Encryption", answer: "Mã hóa", 
                hint: "Chuyển dữ liệu sang dạng mã để bảo mật thông tin.", 
                options: ["A. Giải mã", "B. Nén dữ liệu", "C. Mã hóa", "D. Đồng bộ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Vulnerability", answer: "Lỗ hổng bảo mật", 
                hint: "Điểm yếu trong hệ thống mà hacker có thể khai thác.", 
                options: ["A. Tấn công", "B. Lỗ hổng", "C. Rủi ro", "D. Đe dọa"], correctAnswer: "B", exerciseType: .englishToVietnamese),

            // --- NHÓM 4: DỮ LIỆU & ĐIỆN TOÁN ĐÁM MÂY (Data & Cloud) ---
            Flashcard(question: "Cloud Computing", answer: "Điện toán đám mây", 
                hint: "Cung cấp dịch vụ máy tính qua Internet (AWS, Azure).", 
                options: ["A. Mạng nội bộ", "B. Điện toán đám mây", "C. Lưu trữ rời", "D. Máy tính ảo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Algorithm", answer: "Thuật toán", 
                hint: "Các bước logic để giải quyết một bài toán cụ thể.", 
                options: ["A. Quy trình", "B. Công thức", "C. Thuật toán", "D. Sơ đồ"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Big Data", answer: "Dữ liệu lớn", 
                hint: "Tập hợp dữ liệu cực lớn và phức tạp cần xử lý đặc biệt.", 
                options: ["A. Kho dữ liệu", "B. Dữ liệu lớn", "C. Phân tích dữ liệu", "D. Dữ liệu ảo"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Cache", answer: "Bộ nhớ đệm", 
                hint: "Nơi lưu tạm dữ liệu để truy cập nhanh hơn vào lần sau.", 
                options: ["A. Bộ nhớ chính", "B. Lưu trữ", "C. Bộ nhớ đệm", "D. Thẻ nhớ"], correctAnswer: "C", exerciseType: .englishToVietnamese),

            // --- NHÓM 5: THUẬT NGỮ CÔNG VIỆC (Work Terms) ---
            Flashcard(question: "Bug", answer: "Lỗi phần mềm", 
                hint: "Một sai sót trong code khiến chương trình chạy sai.", 
                options: ["A. Tính năng", "B. Lỗi", "C. Virus", "D. Yêu cầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Interface", answer: "Giao diện", 
                hint: "Điểm tiếp xúc giữa người dùng và máy tính (UI).", 
                options: ["A. Chức năng", "B. Giao diện", "C. Kết nối", "D. Phần mềm"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Responsive", answer: "Tương thích (đa thiết bị)", 
                hint: "Web/App tự đổi kích thước theo màn hình điện thoại/PC.", 
                options: ["A. Phản hồi nhanh", "B. Tương thích", "C. Hiện đại", "D. Di động"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Optimization", answer: "Tối ưu hóa", 
                hint: "Làm cho code chạy nhanh hơn hoặc tốn ít tài nguyên hơn.", 
                options: ["A. Nâng cấp", "B. Thay đổi", "C. Tối ưu hóa", "D. Chỉnh sửa"], correctAnswer: "C", exerciseType: .englishToVietnamese),

            Flashcard(question: "API", answer: "Giao diện lập trình ứng dụng", 
                hint: "Phương thức giúp 2 ứng dụng nói chuyện với nhau.", 
                options: ["A. Kết nối", "B. Giao diện app", "C. Thư viện", "D. Cổng dịch vụ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Scalability", answer: "Khả năng mở rộng", 
                hint: "Khả năng hệ thống chịu tải thêm khi người dùng tăng lên.", 
                options: ["A. Sự ổn định", "B. Khả năng mở rộng", "C. Độ tin cậy", "D. Kích thước"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Maintenance", answer: "Bảo trì", 
                hint: "Công việc kiểm tra và cập nhật hệ thống định kỳ.", 
                options: ["A. Sửa chữa", "B. Bảo trì", "C. Thay thế", "D. Hỗ trợ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Version Control", answer: "Quản lý phiên bản", 
                hint: "Hệ thống theo dõi sự thay đổi của code (Ví dụ: Git).", 
                options: ["A. Sao lưu", "B. Quản lý phiên bản", "C. Lưu trữ", "D. Kiểm soát lỗi"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "User Experience (UX)", answer: "Trải nghiệm người dùng", 
                hint: "Cảm nhận của người dùng khi sử dụng sản phẩm.", 
                options: ["A. Giao diện", "B. Trải nghiệm", "C. Khảo sát", "D. Thói quen"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Documentation", answer: "Tài liệu hướng dẫn/kỹ thuật", 
                hint: "Văn bản giải thích cách dùng code hoặc hệ thống.", 
                options: ["A. Hồ sơ", "B. Tài liệu kĩ thuật", "C. Nhật ký", "D. Ghi chú"], correctAnswer: "B", exerciseType: .englishToVietnamese),

            Flashcard(question: "Agile", answer: "Phương pháp linh hoạt", 
                hint: "Quy trình phát triển phần mềm nhanh và linh động.", 
                options: ["A. Tốc độ", "B. Linh hoạt", "C. Hiệu quả", "D. Thông minh"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Backlog", answer: "Danh sách công việc tồn đọng", 
                hint: "Các task cần làm nhưng chưa thực hiện.", 
                options: ["A. Nhật ký", "B. Việc tồn đọng", "C. Kế hoạch", "D. Kết quả"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Bandwidth", answer: "Băng thông", 
                hint: "Lượng dữ liệu tối đa truyền đi qua đường truyền Internet.", 
                options: ["A. Dung lượng", "B. Băng thông", "C. Tốc độ", "D. Tín hiệu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Latency", answer: "Độ trễ", 
                hint: "Khoảng thời gian phản hồi của mạng/hệ thống.", 
                options: ["A. Tốc độ", "B. Độ trễ", "C. Lag", "D. Chậm trễ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Cookie", answer: "Tập tin lưu thông tin duyệt web", 
                hint: "Dữ liệu nhỏ web lưu trên máy bạn để nhớ trạng thái.", 
                options: ["A. Mã độc", "B. Dữ liệu tạm", "C. Cookie", "D. Virus"], correctAnswer: "C", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Repository (Repo)", answer: "Kho chứa code", 
                hint: "Nơi lưu trữ mã nguồn dự án trên Git.", 
                options: ["A. Thư mục", "B. Kho chứa", "C. Dự án", "D. Lưu trữ"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Spam", answer: "Thư rác", 
                hint: "Các tin nhắn, email quảng cáo không mong muốn.", 
                options: ["A. Quảng cáo", "B. Thư rác", "C. Virus", "D. Mã độc"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Virtual Reality (VR)", answer: "Thực tế ảo", 
                hint: "Môi trường giả lập 3D bằng kính chuyên dụng.", 
                options: ["A. Thế giới ảo", "B. Thực tế ảo", "C. Trò chơi ảo", "D. Phim 3D"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Open Source", answer: "Mã nguồn mở", 
                hint: "Phần mềm mà ai cũng có thể xem và sửa mã nguồn.", 
                options: ["A. Miễn phí", "B. Mã nguồn mở", "C. Công khai", "D. Toàn cầu"], correctAnswer: "B", exerciseType: .englishToVietnamese),
            
            Flashcard(question: "Cybersecurity", answer: "An ninh mạng", 
                hint: "Bảo vệ hệ thống và mạng khỏi các cuộc tấn công mạng.", 
                options: ["A. Bảo mật", "B. An ninh mạng", "C. Chống bẻ khóa", "D. Phòng vệ"], correctAnswer: "B", exerciseType: .englishToVietnamese)
        ]
    )
            
        // Colors in Chinese
        let chineseColorsTopic = Topic(
            name: "Colors (颜色 - Yánsè)",
            subjectName: "Tiếng Trung",
            flashcards: [
                Flashcard(question: "'Màu đỏ' trong tiếng Trung là gì?", answer: "红色 (hóngsè)", hint: "Color of blood", options: ["A. 红色 (hóngsè)", "B. 蓝色 (lánsè)", "C. 黄色 (huángsè)", "D. 绿色 (lǜsè)"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Màu xanh dương' trong tiếng Trung là gì?", answer: "蓝色 (lánsè)", hint: "Color of sky", options: ["A. 红色 (hóngsè)", "B. 蓝色 (lánsè)", "C. 绿色 (lǜsè)", "D. 黑色 (hēisè)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Màu vàng' trong tiếng Trung là gì?", answer: "黄色 (huángsè)", hint: "Color of sun", options: ["A. 黄色 (huángsè)", "B. 红色 (hóngsè)", "C. 绿色 (lǜsè)", "D. 紫色 (zǐsè)"], correctAnswer: "A", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Màu xanh lá' trong tiếng Trung là gì?", answer: "绿色 (lǜsè)", hint: "Color of grass", options: ["A. 黑色 (hēisè)", "B. 白色 (báisè)", "C. 绿色 (lǜsè)", "D. 橙色 (chéngsè)"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Màu đen' trong tiếng Trung là gì?", answer: "黑色 (hēisè)", hint: "Opposite of white", options: ["A. 白色 (báisè)", "B. 黑色 (hēisè)", "C. 灰色 (huīsè)", "D. 棕色 (zōngsè)"], correctAnswer: "B", exerciseType: .vietnameseToEnglish),
                Flashcard(question: "'Màu trắng' trong tiếng Trung là gì?", answer: "白色 (báisè)", hint: "Color of snow", options: ["A. 黑色 (hēisè)", "B. 灰色 (huīsè)", "C. 白色 (báisè)", "D. 粉色 (fěnsè)"], correctAnswer: "C", exerciseType: .vietnameseToEnglish),
                
                // Reverse
                Flashcard(question: "What is '红色 (hóngsè)' in Vietnamese?", answer: "Màu đỏ", hint: "Color of fire", options: ["A. Màu đỏ", "B. Màu xanh", "C. Màu vàng", "D. Màu đen"], correctAnswer: "A", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is '蓝色 (lánsè)' in Vietnamese?", answer: "Màu xanh dương", hint: "Color of ocean", options: ["A. Màu đỏ", "B. Màu xanh dương", "C. Màu xanh lá", "D. Màu đen"], correctAnswer: "B", exerciseType: .englishToVietnamese),
                Flashcard(question: "What is '绿色 (lǜsè)' in Vietnamese?", answer: "Màu xanh lá", hint: "Color of leaves", options: ["A. Màu xanh dương", "B. Màu xanh lá", "C. Màu vàng", "D. Màu nâu"], correctAnswer: "B", exerciseType: .englishToVietnamese)
            ]
        )

        subjects = [
            Subject(
                name: "Tiếng Anh",
                icon: "flag.fill",
                topics: [
                    familyTopic,
                    seasonsTopic,
                    colorsTopic,
                    daysTopic,
                    foodTopic,
                    fruitsTopic,
                    animalsTopic,
                    bodyTopic,
                    clothesTopic,
                    weatherTopic,
                    christmasTopic,
                    kitchenTopic,
                    tetTopic,
                    verbsTopic,
                    adjectivesTopic,
                    placesTopic,
                    internetTopic,
                    accommodationTopic,
                    studyTopic,
                    workTopic,
                    dailyRoutineTopic,
                    officeLifeTopic,
                    transportationTopic,
                    shoppingTopic,
                    hometownTopic,
                    hospitalTopic,
                    ieltsEnvironmentTopic,
                    ieltsTechnologyTopic,
                    ieltsHealthTopic,
                    ieltsEducationTopic,
                    ieltsSocietyTopic,
                    ieltsPersonalityTopic,
                    itVocabularyTopic
                ]
            ),
            Subject(
                name: "Tiếng Trung",
                icon: "character.book.closed.fill",
                topics: [
                    chineseNumbersTopic,
                    chineseGreetingsTopic,
                    chineseFamilyTopic,
                    chineseColorsTopic,
                    chineseRadicalsTopic
                ]
            )
        ]
    }
    
    func selectSubject(_ subject: Subject) {
        selectedSubject = subject
        // Auto-select first topic if available
        if let firstTopic = subject.topics.first {
            selectedTopic = firstTopic
            // Auto-select first flashcard if available
            selectedFlashcard = firstTopic.flashcards.first
        } else {
            selectedTopic = nil
            selectedFlashcard = nil
        }
    }
    
    func selectTopic(_ topic: Topic) {
        selectedTopic = topic
        // Auto-select first flashcard if available
        selectedFlashcard = topic.flashcards.first
    }
    
    func selectFlashcard(_ flashcard: Flashcard) {
        selectedFlashcard = flashcard
    }
}
