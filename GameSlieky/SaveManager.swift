import Foundation

enum SaveManager {
    private static let fileName = "save.json"

    private static var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    static func hasSave() -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func save(_ engine: GameEngine) {
        // Only persist ongoing battles
        guard engine.outcome == .ongoing else { clear(); return }
        do {
            let data = try JSONEncoder().encode(engine)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("SaveManager.save error: \(error)")
        }
    }

    static func load() -> GameEngine? {
        guard hasSave() else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(GameEngine.self, from: data)
        } catch {
            print("SaveManager.load error: \(error)")
            return nil
        }
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
