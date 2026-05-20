import Foundation
import SwiftUI
import Observation

@Observable
final class GameEngine {
    // MARK: - Tunables
    static let startingLayers = 6
    static let cardsPerLayerCollapse = 4
    static let playerMaxHP = 20
    static let bossMaxHP = 40
    static let handSize = 1   // one card per type slot

    // MARK: - State
    var layers: Int = startingLayers
    var playerHP: Int = playerMaxHP
    var playerShield: Int = 0
    var bossHP: Int = bossMaxHP
    var bossFrozen: Bool = false

    var entities: [Entity] = []

    // Piles + hand: one slot per type, drawn from its own pile.
    var attackPile: [Card] = CardLibrary.makeAttackPile()
    var defendPile: [Card] = CardLibrary.makeDefendPile()
    var utilityPile: [Card] = CardLibrary.makeUtilityPile()

    var attackHand: Card?
    var defendHand: Card?
    var utilityHand: Card?

    // Counters
    var cardsPlayed: Int = 0
    var bossActionCounter: Int = 0    // for boss action variety
    var log: [String] = []

    enum Outcome { case ongoing, victory, defeat }
    var outcome: Outcome = .ongoing

    init() { startNewGame() }

    func startNewGame() {
        layers = Self.startingLayers
        playerHP = Self.playerMaxHP
        playerShield = 0
        bossHP = Self.bossMaxHP
        bossFrozen = false
        entities.removeAll()
        attackPile = CardLibrary.makeAttackPile()
        defendPile = CardLibrary.makeDefendPile()
        utilityPile = CardLibrary.makeUtilityPile()
        cardsPlayed = 0
        bossActionCounter = 0
        log.removeAll()
        outcome = .ongoing
        drawIntoSlot(.attack)
        drawIntoSlot(.defend)
        drawIntoSlot(.utility)
        addLog("Battle begins. \(layers) layers.")
    }

    // MARK: - Drawing

    func drawIntoSlot(_ type: CardType) {
        switch type {
        case .attack:
            if attackPile.isEmpty { attackPile = CardLibrary.makeAttackPile() }
            attackHand = attackPile.removeFirst()
        case .defend:
            if defendPile.isEmpty { defendPile = CardLibrary.makeDefendPile() }
            defendHand = defendPile.removeFirst()
        case .utility:
            if utilityPile.isEmpty { utilityPile = CardLibrary.makeUtilityPile() }
            utilityHand = utilityPile.removeFirst()
        }
    }

    func currentCard(for type: CardType) -> Card? {
        switch type {
        case .attack:  return attackHand
        case .defend:  return defendHand
        case .utility: return utilityHand
        }
    }

    // MARK: - Turn flow

    func play(_ type: CardType) {
        guard outcome == .ongoing, let card = currentCard(for: type) else { return }

        // 1. Resolve card effect
        resolve(card)

        // 2. Clear and redraw that slot
        switch type {
        case .attack:  attackHand = nil
        case .defend:  defendHand = nil
        case .utility: utilityHand = nil
        }
        drawIntoSlot(type)

        // 3. Check victory before boss acts
        if bossHP <= 0 { outcome = .victory; addLog("Boss defeated!"); return }

        // 4. Boss acts (unless frozen)
        if bossFrozen {
            bossFrozen = false
            addLog("Boss is frozen — skips turn.")
        } else {
            bossAct()
        }

        // 5. Advance entities and check if they hit player
        advanceEntities()

        // 6. Layer-collapse counter
        cardsPlayed += 1
        if cardsPlayed % Self.cardsPerLayerCollapse == 0 {
            collapseLayer()
        }

        // 7. Check defeat
        if playerHP <= 0 { outcome = .defeat; addLog("You fall.") }
        if layers <= 0 && outcome == .ongoing {
            // Boss is upon you — direct hits each turn
            outcome = .defeat
            addLog("The boss is upon you — defeat.")
        }
    }

    // MARK: - Card resolution

    private func resolve(_ card: Card) {
        addLog("▶︎ \(card.name)")
        switch card.effect {
        case .strike(let dmg):
            // damages nearest entity; if none, hits boss
            if let nearest = nearestEntityIndex() {
                damageEntity(at: nearest, amount: dmg)
            } else {
                damageBoss(dmg)
            }
        case .pierce(let dmg):
            damageBoss(dmg)
        case .cleave(let dmg):
            for i in entities.indices {
                damageEntity(at: i, amount: dmg, silent: true)
            }
            entities.removeAll { entityHP($0) <= 0 }
            addLog("Cleave hits all entities for \(dmg).")
        case .block(let amount):
            playerShield += amount
            addLog("Shield → \(playerShield).")
        case .taunt(let n):
            pushEntitiesUp(by: n)
        case .freeze:
            bossFrozen = true
            addLog("Boss frozen.")
        case .draw:
            // not currently wired; placeholder
            break
        case .heal(let amount):
            playerHP = min(Self.playerMaxHP, playerHP + amount)
            addLog("Healed → HP \(playerHP).")
        }
    }

    private func entityHP(_ entity: Entity) -> Int {
        switch entity.kind {
        case .minion(let hp, _):    return hp
        case .projectile(let dmg):  return dmg  // projectiles "die" when they hit
        }
    }

    private func nearestEntityIndex() -> Int? {
        // Lowest layer = closest to player
        guard !entities.isEmpty else { return nil }
        return entities.indices.min { entities[$0].layer < entities[$1].layer }
    }

    private func damageEntity(at index: Int, amount: Int, silent: Bool = false) {
        guard entities.indices.contains(index) else { return }
        switch entities[index].kind {
        case .minion(let hp, let dmg):
            let newHP = hp - amount
            if newHP <= 0 {
                if !silent { addLog("Minion destroyed.") }
                entities.remove(at: index)
            } else {
                entities[index].kind = .minion(hp: newHP, damage: dmg)
                if !silent { addLog("Minion → \(newHP) HP.") }
            }
        case .projectile:
            entities.remove(at: index)
            if !silent { addLog("Projectile destroyed.") }
        }
    }

    private func damageBoss(_ amount: Int) {
        bossHP = max(0, bossHP - amount)
        addLog("Boss → \(bossHP) HP.")
    }

    private func pushEntitiesUp(by n: Int) {
        let topLayer = max(0, layers - 1)
        for i in entities.indices {
            entities[i].layer = min(topLayer, entities[i].layer + n)
        }
        addLog("Entities pushed back \(n).")
    }

    // MARK: - Boss

    private func bossAct() {
        bossActionCounter += 1
        // Boss can't spawn on or beyond the top layer; spawn just below boss
        let spawnLayer = max(0, layers - 1)
        guard spawnLayer >= 0 else { return }

        // Alternate spawn patterns for variety
        switch bossActionCounter % 3 {
        case 0:
            // Heavy minion every third turn
            entities.append(Entity(kind: .minion(hp: 4, damage: 4), layer: spawnLayer))
            addLog("Boss summons a heavy minion.")
        case 1:
            entities.append(Entity(kind: .projectile(damage: 3), layer: spawnLayer))
            addLog("Boss hurls a projectile.")
        default:
            entities.append(Entity(kind: .minion(hp: 2, damage: 2), layer: spawnLayer))
            addLog("Boss summons a minion.")
        }
    }

    private func advanceEntities() {
        // Each entity moves down 1 layer toward player
        var hits: [Entity] = []
        for i in entities.indices {
            entities[i].layer -= 1
            if entities[i].layer < 0 {
                hits.append(entities[i])
            }
        }
        // Apply hits & remove
        entities.removeAll { $0.layer < 0 }
        for hit in hits {
            applyPlayerDamage(hit.attackPower, source: hit)
        }
    }

    private func applyPlayerDamage(_ amount: Int, source: Entity) {
        var dmg = amount
        if playerShield > 0 {
            let absorbed = min(playerShield, dmg)
            playerShield -= absorbed
            dmg -= absorbed
            if absorbed > 0 { addLog("Shield absorbs \(absorbed).") }
        }
        if dmg > 0 {
            playerHP = max(0, playerHP - dmg)
            switch source.kind {
            case .minion:     addLog("Minion hits you for \(dmg).")
            case .projectile: addLog("Projectile hits you for \(dmg).")
            }
        }
    }

    private func collapseLayer() {
        layers -= 1
        // Clamp entities into the smaller battlefield; anything above new top sits at new top
        let topLayer = max(0, layers - 1)
        for i in entities.indices {
            entities[i].layer = min(entities[i].layer, topLayer)
        }
        addLog("⚠︎ Boss destroys a layer. Layers: \(layers).")
    }

    // MARK: - Log

    private func addLog(_ message: String) {
        log.append(message)
        if log.count > 30 { log.removeFirst(log.count - 30) }
    }
}
