import SwiftUI

@main
struct GameSliekyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root navigation

enum AppScreen {
    case menu
    case deckBuilder
    case game(GameEngine)
}

@Observable
final class AppRouter {
    var screen: AppScreen = .menu

    func goToMenu() { screen = .menu }
    func goToDeckBuilder() { screen = .deckBuilder }
    func startGame(with deck: DeckSpec) {
        let engine = GameEngine(deck: deck)
        SaveManager.save(engine)
        screen = .game(engine)
    }
    func continueGame() {
        if let engine = SaveManager.load() {
            screen = .game(engine)
        }
    }
}

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        switch router.screen {
        case .menu:
            MainMenuView(router: router)
        case .deckBuilder:
            DeckBuilderView(router: router)
        case .game(let engine):
            GameView(engine: engine, router: router)
        }
    }
}
