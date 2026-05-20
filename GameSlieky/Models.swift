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
}

struct Card: Identifiable, Equatable {
    let id = UUID()
    let type: CardType
    let name: String
    let value: Int          // damage / shield / utility magnitude
    let subtitle: String    // short rules text
    let effect: CardEffect
}

enum CardEffect: Equatable {
    case strike(damage: Int)            // damage closest entity, overflow to boss only if lane clear
    case pierce(damage: Int)            // damage boss directly, ignoring entities
    case cleave(damage: Int)            // damage every entity on battlefield
    case block(shield: Int)             // gain shield (absorbs next incoming damage)
    case taunt(layers: Int)             // pushes nearest N entities back up N layer
    case freeze                         // boss skips next action
    case draw(extra: Int)               // refill + draw extra (utility flavor)
    case heal(amount: Int)              // restore player HP
}

// MARK: - Battlefield entities

enum EntityKind: Equatable {
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

struct Entity: Identifiable, Equatable {
    let id = UUID()
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
