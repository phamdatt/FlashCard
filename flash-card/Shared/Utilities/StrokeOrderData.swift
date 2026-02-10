//
//  StrokeOrderData.swift
//  flash-card
//
//  Thứ tự nét viết chữ Hán (stroke order). Dùng cho tính năng "Cách viết hán tự" (kiểu Hanzi app).
//  Nguồn: quy tắc chuẩn (横 竖 撇 捺 点 提 折 钩), số thứ tự nét tham khảo Unihan/IDS.
//

import Foundation

/// Loại nét cơ bản (CJK): tên tiếng Việt + mô tả ngắn.
enum StrokeType: String, CaseIterable {
    case horizontal = "h"   // 横 héng - nét ngang
    case vertical = "v"     // 竖 shù - nét sổ
    case leftSlant = "p"    // 撇 piě - phẩy (trái)
    case rightSlant = "n"   // 捺 nà - mác (phải)
    case dot = "d"          // 点 diǎn - chấm
    case rise = "t"         // 提 tí - hất
    case turn = "z"         // 折 zhé - gấp
    case hook = "g"         // 钩 gōu - móc

    var vietnameseName: String {
        switch self {
        case .horizontal: return "Ngang"
        case .vertical: return "Sổ"
        case .leftSlant: return "Phẩy"
        case .rightSlant: return "Mác"
        case .dot: return "Chấm"
        case .rise: return "Hất"
        case .turn: return "Gấp"
        case .hook: return "Móc"
        }
    }

    var chineseName: String {
        switch self {
        case .horizontal: return "横"
        case .vertical: return "竖"
        case .leftSlant: return "撇"
        case .rightSlant: return "捺"
        case .dot: return "点"
        case .rise: return "提"
        case .turn: return "折"
        case .hook: return "钩"
        }
    }

    static func from(raw: String) -> StrokeType? {
        StrokeType(rawValue: raw)
    }
}

enum StrokeOrderData {
    /// Thứ tự nét: mỗi chữ là chuỗi các mã nét (h, v, p, n, d, t, z, g). Nil = không có dữ liệu.
    private static let order: [Character: String] = [
        "一": "h",
        "二": "hh",
        "三": "hhh",
        "十": "hv",
        "人": "pn",
        "入": "pn",
        "八": "pn",
        "儿": "pg",
        "口": "zhhz",
        "日": "zhhhz",
        "月": "phhh",
        "木": "hvhv",
        "水": "vgph",
        "火": "pnp",
        "土": "hvh",
        "大": "hpn",
        "小": "vdv",
        "中": "zhvz",
        "上": "hvh",
        "下": "hvd",
        "天": "hhpn",
        "生": "hvhvh",
        "了": "pg",
        "子": "phh",
        "不": "hdvp",
        "有": "hphhh",
        "在": "hvhvh",
        "我": "phgphn",
        "他": "pphv",
        "你": "pphvp",
        "们": "pphz",
        "来": "hvvpn",
        "去": "hvhv",
        "会": "phhhz",
        "学": "phhhp",
        "习": "ppg",
        "工": "hhv",
        "好": "phhpn",
        "也": "pgv",
        "的": "phhpg",
        "和": "hhvhv",
        "说": "hvpnp",
        "看": "hhvhv",
        "听": "hvhvp",
        "吃": "hvp",
        "书": "hhvz",
        "写": "phhh",
        "字": "phhhv",
        "读": "hvhvp",
        "话": "hvhvz",
        "文": "pdvn",
        "汉": "vphhn",
        "语": "hvhvz",
        "词": "hvhvz",
        "老": "hvpnp",
        "师": "hvhvz",
        "同": "zhhvz",
        "没": "vphhn",
        "想": "hvpnvzhhhdgdd", // 木(4) + 目(5) + 心(4) = 13 nét chuẩn
        "知": "hvhv",
        "道": "phhvv",
        "能": "pzhhn",
        "可": "hvhv",
        "要": "hvhvn",
        "时": "hvhvz",
        "年": "hvvh",
        "明": "zhhhzphhh",
        "今": "pph",
        "现": "hvhvh",
        "因": "zhhvz",
        "为": "pdn",
        "但": "phhhv",
        "如": "phvz",
        "果": "hvhvv",
        "里": "zhhvz",
        "两": "hvhvv",
        "几": "pg",
        "多": "pnp",
        "少": "vdv",
        "高": "zhhvz",
        "长": "pnv",
        "新": "hvvpn",
        "开": "hvhv",
        "关": "vdvv",
        "买": "dhhv",
        "请": "hvhvz",
        "谢": "hvhvp",
        "爱": "phhhn",
        "喜": "hhvhv",
        "欢": "pnpn",
        "发": "pnpg",
        "音": "zhhvz",
        "练": "hvvpn",
        "留": "hvhvv",
    ]

    /// Trả về mảng thứ tự nét cho một chữ. Nil nếu không có dữ liệu.
    static func strokeOrder(for character: Character) -> [StrokeType]? {
        guard let raw = order[character] else { return nil }
        return raw.compactMap { StrokeType.from(raw: String($0)) }
    }

    /// Trả về true nếu có ít nhất một chữ trong chuỗi có dữ liệu thứ tự nét.
    static func hasStrokeOrder(for text: String) -> Bool {
        text.contains { strokeOrder(for: $0) != nil }
    }
}
