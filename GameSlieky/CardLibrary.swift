import Foundation

enum CardLibrary {
    // Each pile holds many copies; we draw with replacement-style by cycling shuffled decks.

    static func makeAttackPile() -> [Card] {
        var pile: [Card] = []
        // Common strikes
        for _ in 0..<6 {
            pile.append(Card(type: .attack, name: "Strike", value: 3,
                             subtitle: "Damage 3 to nearest",
                             effect: .strike(damage: 3)))
        }
        for _ in 0..<4 {
            pile.append(Card(type: .attack, name: "Heavy Strike", value: 5,
                             subtitle: "Damage 5 to nearest",
                             effect: .strike(damage: 5)))
        }
        // Rarer
        for _ in 0..<3 {
            pile.append(Card(type: .attack, name: "Pierce", value: 4,
                             subtitle: "4 dmg to boss, ignore lane",
                             effect: .pierce(damage: 4)))
        }
        for _ in 0..<2 {
            pile.append(Card(type: .attack, name: "Cleave", value: 2,
                             subtitle: "2 dmg to ALL entities",
                             effect: .cleave(damage: 2)))
        }
        return pile.shuffled()
    }

    static func makeDefendPile() -> [Card] {
        var pile: [Card] = []
        for _ in 0..<7 {
            pile.append(Card(type: .defend, name: "Block", value: 4,
                             subtitle: "Gain 4 shield",
                             effect: .block(shield: 4)))
        }
        for _ in 0..<4 {
            pile.append(Card(type: .defend, name: "Bulwark", value: 7,
                             subtitle: "Gain 7 shield",
                             effect: .block(shield: 7)))
        }
        for _ in 0..<3 {
            pile.append(Card(type: .defend, name: "Push Back", value: 1,
                             subtitle: "Push nearest 1 lane up",
                             effect: .taunt(layers: 1)))
        }
        return pile.shuffled()
    }

    static func makeUtilityPile() -> [Card] {
        var pile: [Card] = []
        for _ in 0..<5 {
            pile.append(Card(type: .utility, name: "Freeze", value: 0,
                             subtitle: "Boss skips next action",
                             effect: .freeze))
        }
        for _ in 0..<4 {
            pile.append(Card(type: .utility, name: "Heal", value: 4,
                             subtitle: "Restore 4 HP",
                             effect: .heal(amount: 4)))
        }
        for _ in 0..<3 {
            pile.append(Card(type: .utility, name: "Foresight", value: 1,
                             subtitle: "Push all entities 1 up",
                             effect: .taunt(layers: 1)))
        }
        return pile.shuffled()
    }
}
