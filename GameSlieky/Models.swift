import Foundation
import SwiftUI

// MARK: - Cards

enum CardType: String, CaseIterable, Codable {
    case attack, defend, utility

    var color: Color {
        switch self {
        case .attack:  return .red
        case .defend:  return .blue
        case .utility: return .yellow
        }
    }

    var icon: String {
        switch self {
        case .attack:  return "flame.fill"
        case .defend:  return "shield.lefthalf.filled"
        case .utility: return "sparkles"
        }
    }

    var title: String {
        switch self {
        case .attack:  return "Attack"
        case .defend:  return "Defend"
        case .utility: return "Utility"
        }
    }
}

/// Card identity uses a stable string name (rather than a per-run UUID)
/// so decks and save files can round-trip through Codable.
struct Card: Identifiable, Equatable, Codable, Hashable {
    var id: String { name }
    let type: CardType
    let name: String
    let value: Int          // headline number shown on the card face
    let subtitle: String    // short rules text
    let effect: CardEffect
}

indirect enum CardEffect: Equatable, Codable, Hashable {
    case damageNearest(Int)     // hit closest entity; if none, hit boss
    case damageBoss(Int)        // pierce: hit boss directly, ignore lane
    case damageAll(Int)         // cleave: hit every entity
    case damageFarthest(Int)    // snipe: hit entity in highest layer
    case shield(Int)            // gain shield
    case pushNearest(Int)       // push closest entity N layers up
    case pushAll(Int)           // push every entity N layers up
    case freezeBoss             // boss skips next turn
    case heal(Int)              // restore player HP
    case combo([CardEffect])    // run a sequence of effects
}

// MARK: - Battlefield entities

enum EntityKind: Equatable, Codable, Hashable {
    case minion(hp: Int, damage: Int)
    case projectile(damage: Int)

    var icon: String {
        switch self {
        case .minion:     return "ant.fill"
        case .projectile: return "burst.fill"
        }
    }

    var tint: Color {
        switch self {
        case .minion:     return .orange
        case .projectile: return .purple
        }
    }
}

struct Entity: Identifiable, Equatable, Codable, Hashable {
    var id = UUID()
    var kind: EntityKind
    var layer: Int    // 0 = at player, higher = farther from player (closer to boss)

    var displayValue: Int {
        switch kind {
        case .minion(let hp, _):    return hp
        case .projectile(let dmg):  return dmg
        }
    }

    var attackPower: Int {
        switch kind {
        case .minion(_, let dmg):   return dmg
        case .projectile(let dmg):  return dmg
        }
    }
}

// MARK: - Deck

/// Player's chosen deck composition. Maps card name → quantity within each type pile.
struct DeckSpec: Codable, Equatable {
    var attack: [String: Int]
    var defend: [String: Int]
    var utility: [String: Int]

    static let minPerType = 5
    static let maxPerType = 10
    static let maxCopiesPerCard = 3

    func quantity(for type: CardType, cardName: String) -> Int {
        switch type {
        case .attack:  return attack[cardName] ?? 0
        case .defend:  return defend[cardName] ?? 0
        case .utility: return utility[cardName] ?? 0
        }
    }

    mutating func setQuantity(_ q: Int, for type: CardType, cardName: String) {
        let clamped = max(0, min(Self.maxCopiesPerCard, q))
        switch type {
        case .attack:  attack[cardName] = clamped
        case .defend:  defend[cardName] = clamped
        case .utility: utility[cardName] = clamped
        }
    }

    func total(for type: CardType) -> Int {
        switch type {
        case .attack:  return attack.values.reduce(0, +)
        case .defend:  return defend.values.reduce(0, +)
        case .utility: return utility.values.reduce(0, +)
        }
    }

    var isValid: Bool {
        CardType.allCases.allSatisfy {
            let n = total(for: $0)
            return n >= Self.minPerType && n <= Self.maxPerType
        }
    }

    /// Default starting deck: 1 of each known card in the catalog (5 per type).
    static var starter: DeckSpec {
        var a: [String: Int] = [:], d: [String: Int] = [:], u: [String: Int] = [:]
        for c in CardLibrary.catalog(for: .attack)  { a[c.name] = 1 }
        for c in CardLibrary.catalog(for: .defend)  { d[c.name] = 1 }
        for c in CardLibrary.catalog(for: .utility) { u[c.name] = 1 }
        return DeckSpec(attack: a, defend: d, utility: u)
    }
}
