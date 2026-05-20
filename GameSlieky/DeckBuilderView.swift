import SwiftUI

struct DeckBuilderView: View {
    let router: AppRouter
    @State private var deck: DeckSpec = .starter
    @State private var selectedType: CardType = .attack

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(white: 0.08)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                typeTabs
                totalsBar
                cardList
                Spacer(minLength: 0)
                bottomBar
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Button {
                router.goToMenu()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            Spacer()
            Text("BUILD YOUR DECK")
                .font(.headline.bold())
                .tracking(2)
                .foregroundStyle(.white)
            Spacer()
            Button {
                deck = .starter
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
        }
    }

    private var typeTabs: some View {
        HStack(spacing: 8) {
            ForEach(CardType.allCases, id: \.self) { type in
                Button {
                    selectedType = type
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                            Text(type.title.uppercased())
                                .font(.caption.bold())
                                .tracking(1)
                        }
                        Text("\(deck.total(for: type))/\(DeckSpec.maxPerType)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedType == type
                            ? type.color.opacity(0.7)
                            : Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var totalsBar: some View {
        let total = deck.total(for: selectedType)
        let min = DeckSpec.minPerType
        let max = DeckSpec.maxPerType
        let inRange = total >= min && total <= max

        return HStack {
            Text("PILE: \(total)").font(.caption.bold().monospacedDigit())
            Text("(min \(min), max \(max))")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Image(systemName: inRange ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(inRange ? .green : .orange)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
    }

    private var cardList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(CardLibrary.catalog(for: selectedType)) { card in
                    DeckBuilderCardRow(
                        card: card,
                        quantity: deck.quantity(for: selectedType, cardName: card.name),
                        onChange: { newQ in
                            deck.setQuantity(newQ, for: selectedType, cardName: card.name)
                        }
                    )
                }
            }
        }
    }

    private var bottomBar: some View {
        Button {
            router.startGame(with: deck)
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("START BATTLE")
                    .font(.headline.bold())
                    .tracking(2)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(deck.isValid ? Color.red.opacity(0.85) : Color.gray.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!deck.isValid)
    }
}

// MARK: - Card row

struct DeckBuilderCardRow: View {
    let card: Card
    let quantity: Int
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.type.color.opacity(0.85))
                    .frame(width: 54, height: 64)
                VStack(spacing: 2) {
                    Image(systemName: card.type.icon).font(.title3)
                    if card.value > 0 {
                        Text("\(card.value)")
                            .font(.caption.bold().monospacedDigit())
                    }
                }
                .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name).font(.subheadline.bold())
                Text(card.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Stepper(
                value: Binding(get: { quantity }, set: { onChange($0) }),
                in: 0...DeckSpec.maxCopiesPerCard
            ) {
                Text("×\(quantity)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(width: 36, alignment: .trailing)
            }
            .labelsHidden()
            .overlay(alignment: .leading) {
                Text("×\(quantity)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.trailing, 100)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.white)
    }
}
