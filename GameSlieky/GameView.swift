import SwiftUI

struct GameView: View {
    @State var engine: GameEngine
    let router: AppRouter

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(white: 0.08)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                BossBar(engine: engine)
                BattlefieldView(engine: engine)
                    .frame(maxHeight: .infinity)
                PlayerBar(engine: engine)
                HandView(engine: engine, onPlay: handlePlay)
                LogStrip(log: engine.log)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if engine.outcome != .ongoing {
                OutcomeOverlay(engine: engine, router: router)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                SaveManager.save(engine)
                router.goToMenu()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            Spacer()
            Text("BATTLE")
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            // Spacer placeholder to balance back button
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func handlePlay(_ type: CardType) {
        engine.play(type)
        if engine.outcome == .ongoing {
            SaveManager.save(engine)
        } else {
            SaveManager.clear()
        }
    }
}

// MARK: - Boss

struct BossBar: View {
    let engine: GameEngine
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.title)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text("BOSS").font(.caption).foregroundStyle(.secondary)
                HPBar(current: engine.bossHP, max: GameEngine.bossMaxHP, tint: .red)
            }
            Spacer()
            if engine.bossFrozen {
                Label("Frozen", systemImage: "snowflake")
                    .font(.caption).foregroundStyle(.cyan)
            }
            VStack(spacing: 2) {
                Text("\(engine.layers)").font(.title.bold()).foregroundStyle(.orange)
                Text("LAYERS").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Battlefield

struct BattlefieldView: View {
    let engine: GameEngine

    var body: some View {
        GeometryReader { geo in
            let layerCount = max(1, engine.layers)
            let rowHeight = geo.size.height / CGFloat(layerCount)

            VStack(spacing: 0) {
                ForEach(layerStackTopDown(), id: \.self) { layerIndex in
                    LayerRow(layerIndex: layerIndex,
                             entities: entitiesInLayer(layerIndex))
                        .frame(height: rowHeight)
                }
            }
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    private func layerStackTopDown() -> [Int] {
        Array((0..<engine.layers).reversed())
    }

    private func entitiesInLayer(_ layer: Int) -> [Entity] {
        engine.entities.filter { $0.layer == layer }
    }
}

struct LayerRow: View {
    let layerIndex: Int
    let entities: [Entity]

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(layerIndex % 2 == 0 ? 0.03 : 0.06))

            HStack {
                Text("L\(layerIndex)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.leading, 6)
                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(entities) { entity in
                    EntityChip(entity: entity)
                }
            }
        }
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

struct EntityChip: View {
    let entity: Entity
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: entity.kind.icon)
                .font(.title2)
            Text("\(entity.displayValue)")
                .font(.caption.bold().monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(entity.kind.tint.opacity(0.7),
                    in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Player

struct PlayerBar: View {
    let engine: GameEngine
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.stand")
                .font(.title)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("YOU").font(.caption).foregroundStyle(.secondary)
                HPBar(current: engine.playerHP, max: GameEngine.playerMaxHP, tint: .green)
            }
            if engine.playerShield > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.blue)
                    Text("\(engine.playerShield)")
                        .font(.caption.bold().monospacedDigit())
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Hand

struct HandView: View {
    let engine: GameEngine
    let onPlay: (CardType) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CardType.allCases, id: \.self) { type in
                if let card = engine.currentCard(for: type) {
                    HandCardView(card: card,
                                 remaining: engine.remainingInPile(type)) {
                        onPlay(type)
                    }
                } else {
                    EmptyCardSlot(type: type)
                }
            }
        }
    }
}

struct HandCardView: View {
    let card: Card
    let remaining: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: card.type.icon).font(.title)
                Text(card.name).font(.headline)
                Text(card.subtitle)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                if card.value > 0 {
                    Text("\(card.value)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.white)
                }
                Text("pile: \(remaining)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(card.type.color.opacity(0.85),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyCardSlot: View {
    let type: CardType
    var body: some View {
        VStack {
            Image(systemName: type.icon)
                .font(.title)
                .foregroundStyle(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Color.white.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - HP

struct HPBar: View {
    let current: Int
    let max: Int
    let tint: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 4)
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(current) / CGFloat(max))
                HStack {
                    Spacer()
                    Text("\(current) / \(max)")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.trailing, 6)
                }
            }
        }
        .frame(height: 14)
    }
}

// MARK: - Log

struct LogStrip: View {
    let log: [String]
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.enumerated()), id: \.offset) { idx, line in
                        Text(line)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.7))
                            .id(idx)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            .frame(height: 70)
            .background(Color.black.opacity(0.3),
                        in: RoundedRectangle(cornerRadius: 8))
            .onChange(of: log.count) { _, _ in
                if let last = log.indices.last {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
        }
    }
}

// MARK: - Outcome overlay

struct OutcomeOverlay: View {
    let engine: GameEngine
    let router: AppRouter

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(engine.outcome == .victory ? "VICTORY" : "DEFEAT")
                    .font(.largeTitle.bold())
                    .foregroundStyle(engine.outcome == .victory ? .green : .red)
                VStack(spacing: 10) {
                    Button("Play Again") {
                        SaveManager.clear()
                        router.startGame(with: engine.deck)
                    }
                    .font(.headline)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(.white.opacity(0.15), in: Capsule())
                    .foregroundStyle(.white)

                    Button("Main Menu") {
                        SaveManager.clear()
                        router.goToMenu()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
