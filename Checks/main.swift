import Foundation

func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    precondition(condition(), label)
}
let directions: [(Double, Double)] = [(30,-30),(30,30),(-30,30),(-30,-30)]
var count = 0
for rank in 1...13 {
    let x = Double((rank - 1) % 3) * 100 + 50
    let y = Double((rank - 1) / 3) * 100 + 50
    for (suit, vector) in directions.enumerated() {
        let card = CardGesture.resolve(x: x, y: y, width: 300, height: 500, dx: vector.0, dy: vector.1)
        check(card == Card(rank: rank, suit: suit), "rank/suit mapping")
        count += 1
    }
    check(CardGesture.resolve(x: x, y: y, width: 300, height: 500, dx: 2, dy: 2) == nil, "accidental tap")
}
for rank in 14...15 {
    check(CardGesture.resolve(x: Double((rank-1)%3)*100+50, y:450, width:300, height:500, dx:0, dy:0)?.rank == rank, "joker tap")
}
check(CardGesture.resolve(x:0,y:0,width:0,height:500,dx:20,dy:20) == nil, "invalid geometry")
check(Set(Card.deck.map(\.asset)).count == 54, "unique assets")
let resourcePath = CommandLine.arguments[1]
for card in Card.deck {
    check(FileManager.default.fileExists(atPath: resourcePath + "/" + card.asset + ".png"), "missing \(card.asset)")
}
print("PASS: \(count) rank/suit gestures, 13 accidental taps, 2 jokers, geometry and all 54 assets")
