import Foundation

/// Catalog of all known cards. The deck builder draws from these; the engine
/// builds shuffled draw piles based on the player's DeckSpec.
enum CardLibrary {

    // MARK: - Attack (5 cards) — focused on different targeting profiles
    static let attackCatalog: [Card] = [
        Card(type: .attack, name: "Strike",       value: 3,
             subtitle: "3 dmg to nearest",
             effect: .damageNearest(3)),
        Card(type: .attack, name: "Heavy Strike", value: 5,
             subtitle: "5 dmg to nearest",
             effect: .damageNearest(5)),
        Card(type: .attack, name: "Pierce",       value: 3,
             subtitle: "3 dmg straight to boss",
             effect: .damageBoss(3)),
        Card(type: .attack, name: "Cleave",       value: 2,
             subtitle: "2 dmg to all entities",
             effect: .damageAll(2)),
        Card(type: .attack, name: "Snipe",        value: 4,
             subtitle: "4 dmg to farthest entity",
             effect: .damageFarthest(4)),
    ]

    // MARK: - Defend (5 cards) — shields plus tempo (push-back)
    static let defendCatalog: [Card] = [
        Card(type: .defend, name: "Block",      value: 4,
             subtitle: "Gain 4 shield",
             effect: .shield(4)),
        Card(type: .defend, name: "Bulwark",    value: 7,
             subtitle: "Gain 7 shield",
             effect: .shield(7)),
        Card(type: .defend, name: "Push Back",  value: 2,
             subtitle: "Push nearest 2 up",
             effect: .pushNearest(2)),
        Card(type: .defend, name: "Brace",      value: 3,
             subtitle: "Gain 3 shield + heal 2",
             effect: .combo([.shield(3), .heal(2)])),
        Card(type: .defend, name: "Phalanx",    value: 5,
             subtitle: "Gain 5 shield + push 1",
             effect: .combo([.shield(5), .pushNearest(1)])),
    ]

    // MARK: - Utility (5 cards) — board manipulation, healing, control
    static let utilityCatalog: [Card] = [
        Card(type: .utility, name: "Freeze",    value: 0,
             subtitle: "Boss skips next turn",
             effect: .freezeBoss),
        Card(type: .utility, name: "Heal",      value: 4,
             subtitle: "Restore 4 HP",
             effect: .heal(4)),
        Card(type: .utility, name: "Foresight", value: 1,
             subtitle: "Push ALL entities 1 up",
             effect: .pushAll(1)),
        Card(type: .utility, name: "Mend",      value: 2,
             subtitle: "Heal 2 + gain 2 shield",
             effect: .combo([.heal(2), .shield(2)])),
        Card(type: .utility, name: "Shockwave", value: 1,
             subtitle: "1 dmg + push ALL 1 up",
             effect: .combo([.damageAll(1), .pushAll(1)])),
    ]

    static func catalog(for type: CardType) -> [Card] {
        switch type {
        case .attack:  return attackCatalog
        case .defend:  return defendCatalog
        case .utility: return utilityCatalog
        }
    }

    /// Build a shuffled draw pile from a deck spec.
    static func makePile(for type: CardType, from deck: DeckSpec) -> [Card] {
        let cards = catalog(for: type)
        var pile: [Card] = []
        for card in cards {
            let n = deck.quantity(for: type, cardName: card.name)
            for _ in 0..<n { pile.append(card) }
        }
        return pile.shuffled()
    }
}
