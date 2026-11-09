import AppKit
import CoreText
import SwiftUI

@main
struct ArcadeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup("Arcade") {
            HubView()
                .frame(minWidth: 1000, minHeight: 780)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1280, height: 860)
        .commands { CommandGroup(replacing: .newItem) {} }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // The hub's own fonts ship in Resources/fonts.
        if let fonts = Bundle.main.resourceURL?.appendingPathComponent("fonts"),
           let files = try? FileManager.default.contentsOfDirectory(at: fonts, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "ttf" {
                CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // macOS relaunches an app hidden if it last ended while hidden (e.g. during a game).
        NSApp.unhide(nil)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

enum HubFont {
    static func title(_ size: CGFloat) -> Font { .custom("RubikWetPaint-Regular", size: size) }
    static func pixel(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Silkscreen-Bold" : "Silkscreen-Regular", size: size)
    }
}
