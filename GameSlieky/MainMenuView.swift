import SwiftUI

struct MainMenuView: View {
    let router: AppRouter
    @State private var hasSave: Bool = SaveManager.hasSave()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.1, green: 0.0, blue: 0.15)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                    Text("GAMESLIEKY")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(4)
                    Text("a roguelike card brawl")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(2)
                }

                Spacer()

                VStack(spacing: 14) {
                    MenuButton(title: "START",
                               subtitle: "Build a new deck",
                               systemImage: "play.fill",
                               isPrimary: true) {
                        SaveManager.clear()
                        router.goToDeckBuilder()
                    }

                    MenuButton(title: "CONTINUE",
                               subtitle: hasSave ? "Resume your battle" : "No saved game",
                               systemImage: "arrow.uturn.forward",
                               isPrimary: false,
                               disabled: !hasSave) {
                        router.continueGame()
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
        .onAppear { hasSave = SaveManager.hasSave() }
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isPrimary: Bool
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.bold())
                        .tracking(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                isPrimary
                    ? Color.red.opacity(0.85)
                    : Color.white.opacity(0.10),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
