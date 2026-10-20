import Foundation

struct Card: Equatable, Identifiable, Sendable {
    let rank: Int
    let suit: Int
    var id: String { asset }
    var rankLabel: String { Self.ranks[rank - 1] }
    static let ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "小王", "大王"]
    var name: String { rank > 13 ? rankLabel : ["黑桃", "红桃", "梅花", "方块"][suit] + rankLabel }
    var asset: String {
        if rank == 14 { return "xiaowang" }
        if rank == 15 { return "dawang" }
        return ["heitao", "hongtao", "meihua", "fangpian"][suit] + "_" + rankLabel
    }
    static let deck: [Card] = (1...13).flatMap { rank in (0...3).map { Card(rank: rank, suit: $0) } } + [Card(rank: 14, suit: 0), Card(rank: 15, suit: 0)]
}

// Adapted from Wombat_Magic_Poker's GridSwipeCardSelector (MIT).
enum CardGesture {
    static func resolve(x: Double, y: Double, width: Double, height: Double, dx: Double, dy: Double) -> Card? {
        guard width > 0, height > 0 else { return nil }
        let column = min(2, max(0, Int(floor(x / (width / 3)))))
        let row = min(4, max(0, Int(floor(y / (height / 5)))))
        let rank = row * 3 + column + 1
        if rank > 13 { return Card(rank: rank, suit: 0) }
        guard hypot(dx, dy) >= 8 else { return nil }
        let angle = (atan2(dx, -dy) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        return Card(rank: rank, suit: min(3, Int(angle / 90)))
    }
}
