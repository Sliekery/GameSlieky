import Foundation
import SwiftUI
import Observation

@Observable
final class GameEngine: Codable {

    // MARK: - Tunables
    static let startingLayers = 6
    static let cardsPerLayerCollapse = 4
    static let playerMaxHP = 20
    static let bossMaxHP = 40

    // MARK: - State
    var deck: DeckSpec
    var layers: Int
    var playerHP: Int
    var playerShield: Int
    var bossHP: Int
    var bossFrozen: Bool

    var entities: [Entity]

    var attackPile: [Card]
    var defendPile: [Card]
    var utilityPile: [Card]

    var attackHand: Card?
    var defendHand: Card?
    var utilityHand: Card?

    var cardsPlayed: Int
    var bossActionCounter: Int
    var log: [String]

    enum Outcome: String, Codable { case ongoing, victory, defeat }
    var outcome: Outcome

    // MARK: - Init

    init(deck: DeckSpec = .starter) {
        self.deck = deck
        self.layers = Self.startingLayers
        self.playerHP = Self.playerMaxHP
        self.playerShield = 0
        self.bossHP = Self.bossMaxHP
        self.bossFrozen = false
        self.entities = []
        self.attackPile = CardLibrary.makePile(for: .attack,  from: deck)
        self.defendPile = CardLibrary.makePile(for: .defend,  from: deck)
        self.utilityPile = CardLibrary.makePile(for: .utility, from: deck)
        self.attackHand = nil
        self.defendHand = nil
        self.utilityHand = nil
        self.cardsPlayed = 0
        self.bossActionCounter = 0
        self.log = []
        self.outcome = .ongoing
        drawIntoSlot(.attack)
        drawIntoSlot(.defend)
        drawIntoSlot(.utility)
        addLog("Battle begins. \(layers) layers.")
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case deck, layers, playerHP, playerShield, bossHP, bossFrozen
        case entities, attackPile, defendPile, utilityPile
        case attackHand, defendHand, utilityHand
        case cardsPlayed, bossActionCounter, log, outcome
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        deck = try c.decode(DeckSpec.self, forKey: .deck)
        layers = try c.decode(Int.self, forKey: .layers)
        playerHP = try c.decode(Int.self, forKey: .playerHP)
        playerShield = try c.decode(Int.self, forKey: .playerShield)
        bossHP = try c.decode(Int.self, forKey: .bossHP)
        bossFrozen = try c.decode(Bool.self, forKey: .bossFrozen)
        entities = try c.decode([Entity].self, forKey: .entities)
        attackPile = try c.decode([Card].self, forKey: .attackPile)
        defendPile = try c.decode([Card].self, forKey: .defendPile)
        utilityPile = try c.decode([Card].self, forKey: .utilityPile)
        attackHand = try c.decodeIfPresent(Card.self, forKey: .attackHand)
        defendHand = try c.decodeIfPresent(Card.self, forKey: .defendHand)
        utilityHand = try c.decodeIfPresent(Card.self, forKey: .utilityHand)
        cardsPlayed = try c.decode(Int.self, forKey: .cardsPlayed)
        bossActionCounter = try c.decode(Int.self, forKey: .bossActionCounter)
        log = try c.decode([String].self, forKey: .log)
        outcome = try c.decode(Outcome.self, forKey: .outcome)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(deck, forKey: .deck)
        try c.encode(layers, forKey: .layers)
        try c.encode(playerHP, forKey: .playerHP)
        try c.encode(playerShield, forKey: .playerShield)
        try c.encode(bossHP, forKey: .bossHP)
        try c.encode(bossFrozen, forKey: .bossFrozen)
        try c.encode(entities, forKey: .entities)
        try c.encode(attackPile, forKey: .attackPile)
        try c.encode(defendPile, forKey: .defendPile)
        try c.encode(utilityPile, forKey: .utilityPile)
        try c.encodeIfPresent(attackHand, forKey: .attackHand)
        try c.encodeIfPresent(defendHand, forKey: .defendHand)
        try c.encodeIfPresent(utilityHand, forKey: .utilityHand)
        try c.encode(cardsPlayed, forKey: .cardsPlayed)
        try c.encode(bossActionCounter, forKey: .bossActionCounter)
        try c.encode(log, forKey: .log)
        try c.encode(outcome, forKey: .outcome)
    }

    // MARK: - Drawing

    func drawIntoSlot(_ type: CardType) {
        switch type {
        case .attack:
            if attackPile.isEmpty { attackPile = CardLibrary.makePile(for: .attack, from: deck) }
            attackHand = attackPile.isEmpty ? nil : attackPile.removeFirst()
        case .defend:
            if defendPile.isEmpty { defendPile = CardLibrary.makePile(for: .defend, from: deck) }
            defendHand = defendPile.isEmpty ? nil : defendPile.removeFirst()
        case .utility:
            if utilityPile.isEmpty { utilityPile = CardLibrary.makePile(for: .utility, from: deck) }
            utilityHand = utilityPile.isEmpty ? nil : utilityPile.removeFirst()
        }
    }

    func currentCard(for type: CardType) -> Card? {
        switch type {
        case .attack:  return attackHand
        case .defend:  return defendHand
        case .utility: return utilityHand
        }
    }

    func remainingInPile(_ type: CardType) -> Int {
        switch type {
        case .attack:  return attackPile.count
        case .defend:  return defendPile.count
        case .utility: return utilityPile.count
        }
    }

    // MARK: - Turn flow

    func play(_ type: CardType) {
        guard outcome == .ongoing, let card = currentCard(for: type) else { return }

        resolve(card.effect, sourceName: card.name)

        switch type {
        case .attack:  attackHand = nil
        case .defend:  defendHand = nil
        case .utility: utilityHand = nil
        }
        drawIntoSlot(type)

        if bossHP <= 0 { outcome = .victory; addLog("Boss defeated!"); return }

        if bossFrozen {
            bossFrozen = false
            addLog("Boss is frozen — skips turn.")
        } else {
            bossAct()
        }

        advanceEntities()

        cardsPlayed += 1
        if cardsPlayed % Self.cardsPerLayerCollapse == 0 {
            collapseLayer()
        }

        if playerHP <= 0 { outcome = .defeat; addLog("You fall."); return }
        if layers <= 0 && outcome == .ongoing {
            outcome = .defeat
            addLog("The boss is upon you — defeat.")
        }
    }

    // MARK: - Effect resolution

    private func resolve(_ effect: CardEffect, sourceName: String? = nil) {
        if let name = sourceName { addLog("▶︎ \(name)") }
        switch effect {
        case .damageNearest(let dmg):
            if let i = nearestEntityIndex() {
                damageEntity(at: i, amount: dmg)
            } else {
                damageBoss(dmg)
            }
        case .damageBoss(let dmg):
            damageBoss(dmg)
        case .damageAll(let dmg):
            for i in entities.indices {
                damageEntity(at: i, amount: dmg, silent: true)
            }
            entities.removeAll { entityHP($0) <= 0 }
            addLog("All entities take \(dmg).")
        case .damageFarthest(let dmg):
            if let i = farthestEntityIndex() {
                damageEntity(at: i, amount: dmg)
            } else {
                damageBoss(dmg)
            }
        case .shield(let amount):
            playerShield += amount
            addLog("Shield → \(playerShield).")
        case .pushNearest(let n):
            pushNearest(by: n)
        case .pushAll(let n):
            pushAll(by: n)
        case .freezeBoss:
            bossFrozen = true
            addLog("Boss frozen.")
        case .heal(let amount):
            playerHP = min(Self.playerMaxHP, playerHP + amount)
            addLog("Healed → HP \(playerHP).")
        case .combo(let effects):
            for sub in effects { resolve(sub) }
        }
    }

    private func entityHP(_ entity: Entity) -> Int {
        switch entity.kind {
        case .minion(let hp, _):    return hp
        case .projectile(let dmg):  return dmg
        }
    }

    private func nearestEntityIndex() -> Int? {
        guard !entities.isEmpty else { return nil }
        return entities.indices.min { entities[$0].layer < entities[$1].layer }
    }

    private func farthestEntityIndex() -> Int? {
        guard !entities.isEmpty else { return nil }
        return entities.indices.max { entities[$0].layer < entities[$1].layer }
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

    private func pushNearest(by n: Int) {
        guard let i = nearestEntityIndex() else { return }
        let topLayer = max(0, layers - 1)
        entities[i].layer = min(topLayer, entities[i].layer + n)
        addLog("Pushed nearest back \(n).")
    }

    private func pushAll(by n: Int) {
        let topLayer = max(0, layers - 1)
        for i in entities.indices {
            entities[i].layer = min(topLayer, entities[i].layer + n)
        }
        addLog("Pushed all back \(n).")
    }

    // MARK: - Boss

    private func bossAct() {
        bossActionCounter += 1
        let spawnLayer = max(0, layers - 1)
        switch bossActionCounter % 3 {
        case 0:
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
        var hits: [Entity] = []
        for i in entities.indices {
            entities[i].layer -= 1
            if entities[i].layer < 0 { hits.append(entities[i]) }
        }
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
