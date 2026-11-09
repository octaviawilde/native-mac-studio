import AppKit
import CoreText

/// One playable game found on disk.
struct Game: Identifiable, Equatable {
    let id: String            // bundle identifier
    let name: String
    let url: URL
    let icon: NSImage
    let fontName: String?     // the game's own title font, registered for this process
    let tagline: String

    static func == (a: Game, b: Game) -> Bool { a.id == b.id && a.url == b.url }
}

/// Finds studio games: app bundles that carry their game data in Contents/Resources/game
/// (or say ArcadeGame = true in Info.plist). Installed copies win over dev builds.
enum GameLibrary {
    static func searchFolders() -> [URL] {
        let fm = FileManager.default
        // Arcade's own folder first: a drive holding Arcade next to its games works anywhere.
        var folders = [Bundle.main.bundleURL.deletingLastPathComponent(),
                       URL(fileURLWithPath: "/Applications"),
                       fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        // Dev builds from the studio's projects (~/Projects/*/dist).
        let projects = fm.homeDirectoryForCurrentUser.appendingPathComponent("Projects")
        if let names = try? fm.contentsOfDirectory(atPath: projects.path) {
            for name in names.sorted() {
                folders.append(projects.appendingPathComponent(name).appendingPathComponent("dist"))
            }
        }
        return folders
    }

    static func scan() -> [Game] {
        let fm = FileManager.default
        var byID: [String: Game] = [:]
        var order: [String] = []
        for folder in searchFolders() {
            guard let names = try? fm.contentsOfDirectory(atPath: folder.path) else { continue }
            for name in names.sorted() where name.hasSuffix(".app") {
                let url = folder.appendingPathComponent(name)
                guard let game = load(url), game.id != Bundle.main.bundleIdentifier else { continue }
                if byID[game.id] == nil { order.append(game.id); byID[game.id] = game }
            }
        }
        return order.compactMap { byID[$0] }
    }

    private static func load(_ url: URL) -> Game? {
        let fm = FileManager.default
        let contents = url.appendingPathComponent("Contents")
        guard let info = NSDictionary(contentsOf: contents.appendingPathComponent("Info.plist")),
              let id = info["CFBundleIdentifier"] as? String else { return nil }
        var isDir: ObjCBool = false
        let hasGameData = fm.fileExists(atPath: contents.appendingPathComponent("Resources/game").path,
                                        isDirectory: &isDir) && isDir.boolValue
        guard hasGameData || (info["ArcadeGame"] as? Bool) == true else { return nil }

        let name = (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let tagline = (info["ArcadeTagline"] as? String) ?? Copy.defaultTagline
        return Game(id: id, name: name, url: url,
                    icon: NSWorkspace.shared.icon(forFile: url.path),
                    fontName: registerFont(contents.appendingPathComponent("Resources/title-font.ttf")),
                    tagline: tagline)
    }

    /// Registers a game's bundled title font and returns its PostScript name.
    private static func registerFont(_ url: URL) -> String? {
        guard FileManager.default.fileExists(atPath: url.path),
              let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let first = descriptors.first,
              let name = CTFontDescriptorCopyAttribute(first, kCTFontNameAttribute) as? String else { return nil }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)  // "already registered" is fine
        return name
    }
}

/// Launches a game, hides the hub while it runs and brings the hub back when it quits.
final class GameLauncher: ObservableObject {
    @Published private(set) var running: Game?
    @Published private(set) var launching: Game?
    private var seenRunning = false
    private var launchedAt = Date.distantPast
    private var awake: NSObjectProtocol?   // keeps App Nap from pausing the checks while hidden

    init() {
        // Watch by bundle identifier: right after launch macOS has no process ID for the game yet,
        // and script-launched games don't always send a termination notice.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.check() }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            if let self, let id = self.running?.id, app?.bundleIdentifier == id { self.check() }
        }
    }

    private func check() {
        guard let game = running else { return }
        let alive = NSRunningApplication.runningApplications(withBundleIdentifier: game.id)
            .contains { !$0.isTerminated }
        if alive {
            seenRunning = true
        } else if seenRunning || Date().timeIntervalSince(launchedAt) > 30 {
            running = nil
            if let awake { ProcessInfo.processInfo.endActivity(awake); self.awake = nil }
            NSApp.unhide(nil)
            NSApp.activate()
            NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
        }
    }

    func launch(_ game: Game) {
        guard running == nil, launching == nil else { return }
        launching = game
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: game.url, configuration: config) { app, error in
            DispatchQueue.main.async {
                self.launching = nil
                guard app != nil, error == nil else { return }
                self.seenRunning = false
                self.launchedAt = Date()
                self.running = game
                self.awake = ProcessInfo.processInfo.beginActivity(
                    options: .userInitiatedAllowingIdleSystemSleep, reason: "Waiting for the game to quit")
                NSApp.hide(nil)
            }
        }
    }
}
