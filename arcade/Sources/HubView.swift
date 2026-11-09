import AppKit
import SwiftUI

struct HubView: View {
    @StateObject private var input = InputHub()
    @StateObject private var launcher = GameLauncher()
    @StateObject private var ui = HubState()

    var body: some View {
        ZStack {
            Backdrop()
            VStack(spacing: 0) {
                header.padding(.top, 26)
                Spacer(minLength: 10)
                if ui.games.isEmpty { emptyState } else { carousel }
                Spacer(minLength: 10)
                promptBar.padding(.bottom, 30)
            }
            if let game = launcher.launching { overlay(Copy.summoning, game.name) }
            if ui.confirmingQuit { quitDialog }
        }
        .onAppear {
            ui.games = GameLibrary.scan()
            input.onAction = handle
            input.start()
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { ui.dripPhase = 1 }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            let current = ui.games.indices.contains(ui.selected) ? ui.games[ui.selected].id : nil
            ui.games = GameLibrary.scan()  // picks up games installed while the hub was away
            ui.selected = ui.games.firstIndex { $0.id == current } ?? min(ui.selected, max(ui.games.count - 1, 0))
        }
    }

    // MARK: Input

    private func handle(_ action: HubAction) {
        guard launcher.launching == nil, launcher.running == nil else { return }
        if ui.confirmingQuit {
            switch action {
            case .left, .right, .up, .down: withAnimation(.spring(duration: 0.25)) { ui.quitChoice = 1 - ui.quitChoice }
            case .confirm: if ui.quitChoice == 0 { NSApp.terminate(nil) } else { closeQuit() }
            case .back, .menu: closeQuit()
            }
            return
        }
        switch action {
        case .left, .up: move(-1)
        case .right, .down: move(1)
        case .confirm: if ui.games.indices.contains(ui.selected) { launcher.launch(ui.games[ui.selected]) }
        case .back: withAnimation(.spring(duration: 0.3)) { ui.quitChoice = 1; ui.confirmingQuit = true }
        case .menu: NSApp.keyWindow?.toggleFullScreen(nil)
        }
    }

    private func move(_ delta: Int) {
        guard !ui.games.isEmpty else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            ui.selected = (ui.selected + delta + ui.games.count) % ui.games.count
        }
    }

    private func closeQuit() { withAnimation(.spring(duration: 0.25)) { ui.confirmingQuit = false } }

    // MARK: Pieces

    private var header: some View {
        VStack(spacing: 6) {
            Text(Copy.title)
                .font(HubFont.title(84))
                .foregroundStyle(LinearGradient(colors: [Palette.bubblegum, Palette.hotPink, Palette.blood],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: .white.opacity(0.9), radius: 0, x: 0, y: -2)
                .shadow(color: Palette.hotPink, radius: 18)
            Text(Copy.subtitle)
                .font(HubFont.pixel(18))
                .foregroundStyle(.white)
                .shadow(color: Palette.blood, radius: 0, x: 2, y: 2)
        }
    }

    private var carousel: some View {
        GeometryReader { geo in
            let cardWidth: CGFloat = 300, spacing: CGFloat = 70
            HStack(spacing: spacing) {
                ForEach(Array(ui.games.enumerated()), id: \.element.id) { index, game in
                    GameCard(game: game, isSelected: index == ui.selected, dripPhase: ui.dripPhase)
                        .frame(width: cardWidth)
                        .onTapGesture(count: 2) { ui.selected = index; handle(.confirm) }
                        .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { ui.selected = index } }
                }
            }
            .offset(x: geo.size.width / 2 - cardWidth / 2 - CGFloat(ui.selected) * (cardWidth + spacing))
            .frame(height: geo.size.height)
        }
        .frame(height: 440)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.slash.fill").font(.system(size: 64)).foregroundStyle(Palette.blood)
            Text(Copy.noGames).font(HubFont.pixel(28, bold: true)).foregroundStyle(.white)
            Text(Copy.noGamesHint)
                .font(HubFont.pixel(14)).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85))
        }
        .padding(40)
        .background(RoundedRectangle(cornerRadius: 34).fill(Palette.night.opacity(0.6)))
    }

    private var promptBar: some View {
        HStack(spacing: 34) {
            if !ui.games.isEmpty { Prompt(device: input.device, slot: .confirm, label: Copy.play) }
            Prompt(device: input.device, slot: .menu, label: Copy.fullscreen)
            Prompt(device: input.device, slot: .back, label: Copy.quit)
        }
        .padding(.horizontal, 30).padding(.vertical, 14)
        .background(Capsule().fill(Palette.night.opacity(0.65)))
        .overlay(Capsule().strokeBorder(Palette.chrome, lineWidth: 3))
        .shadow(color: Palette.hotPink.opacity(0.7), radius: 14)
    }

    private func overlay(_ verb: String, _ name: String) -> some View {
        ZStack {
            Palette.night.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(verb).font(HubFont.title(64)).foregroundStyle(Palette.hotPink)
                    .shadow(color: Palette.blood, radius: 12)
                Text(name).font(HubFont.pixel(22, bold: true)).foregroundStyle(.white)
                ProgressView().controlSize(.large).tint(Palette.bubblegum)
            }
        }
        .transition(.opacity)
    }

    private var quitDialog: some View {
        ZStack {
            Palette.night.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 26) {
                Text(Copy.leaving).font(HubFont.title(48)).foregroundStyle(Palette.bubblegum)
                HStack(spacing: 24) {
                    choice(Copy.quit, index: 0)
                    choice(Copy.stay, index: 1)
                }
            }
            .padding(44)
            .background(RoundedRectangle(cornerRadius: 36).fill(Palette.plum))
            .overlay(RoundedRectangle(cornerRadius: 36).strokeBorder(Palette.chrome, lineWidth: 5))
            .overlay(alignment: .top) {
                Drips(phase: ui.dripPhase).fill(Palette.blood).frame(height: 46).padding(.horizontal, 30).offset(y: 3)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))
    }

    private func choice(_ label: String, index: Int) -> some View {
        let on = ui.quitChoice == index
        return Text(label)
            .font(HubFont.pixel(22, bold: true))
            .foregroundStyle(on ? .white : .white.opacity(0.6))
            .padding(.horizontal, 34).padding(.vertical, 14)
            .background(Capsule().fill(on ? Palette.blood : Palette.night.opacity(0.6)))
            .overlay(Capsule().strokeBorder(on ? AnyShapeStyle(Palette.chrome) : AnyShapeStyle(Color.clear), lineWidth: 3))
            .scaleEffect(on ? 1.08 : 1)
            .onTapGesture { ui.quitChoice = index; handle(.confirm) }
    }
}


/// Screen state kept in an object; the Command Line Tools ship no SwiftUI macro plugin for @State.
final class HubState: ObservableObject {
    @Published var games: [Game] = []
    @Published var selected = 0
    @Published var confirmingQuit = false
    @Published var quitChoice = 1      // 0 = quit, 1 = stay (safe default)
    @Published var dripPhase: CGFloat = 0
}

/// One game: glossy chrome-framed card that bleeds when selected.
struct GameCard: View {
    let game: Game
    let isSelected: Bool
    let dripPhase: CGFloat

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: game.icon)
                .resizable().interpolation(.high).aspectRatio(contentMode: .fit)
                .frame(width: 210, height: 210)
                .shadow(color: .black.opacity(0.45), radius: 10, y: 8)
            Text(game.name)
                .font(game.fontName.map { .custom($0, size: 30) } ?? HubFont.pixel(24, bold: true))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                .shadow(color: Palette.blood, radius: 0, x: 2, y: 2)
            Text(game.tagline)
                .font(HubFont.pixel(12))
                .foregroundStyle(Palette.bubblegum)
                .multilineTextAlignment(.center).lineLimit(2)
        }
        .padding(.horizontal, 22).padding(.top, 36).padding(.bottom, 26)
        .frame(height: 400)
        .background(
            RoundedRectangle(cornerRadius: 38)
                .fill(LinearGradient(colors: [Palette.hotPink.opacity(0.85), Palette.plum, Palette.night],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(  // Y2K gloss highlight
                    RoundedRectangle(cornerRadius: 38)
                        .fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .top, endPoint: .center))
                        .padding(6))
        )
        .overlay(RoundedRectangle(cornerRadius: 38).strokeBorder(Palette.chrome, lineWidth: isSelected ? 6 : 3))
        .overlay(alignment: .top) {
            if isSelected {
                Drips(phase: dripPhase)
                    .fill(LinearGradient(colors: [Palette.blood, Palette.darkBlood], startPoint: .top, endPoint: .bottom))
                    .frame(height: 70).padding(.horizontal, 26).offset(y: 4)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Sparkle().fill(.white).frame(width: 34, height: 34).offset(x: 12, y: -12)
                    .shadow(color: .white, radius: 8)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 0.86)
        .opacity(isSelected ? 1 : 0.6)
        .shadow(color: isSelected ? Palette.blood.opacity(0.8) : .clear, radius: 26)
    }
}

/// A button hint drawn for whatever the player last touched.
struct Prompt: View {
    enum Slot { case confirm, back, menu }
    let device: InputDevice
    let slot: Slot
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            switch device {
            case .keyboard:
                Text(keyName)
                    .font(HubFont.pixel(13, bold: true))
                    .foregroundStyle(Palette.night)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Palette.chrome))
            case let .controller(_, confirm, back, menu):
                Image(systemName: slot == .confirm ? confirm : slot == .back ? back : menu)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white, Palette.hotPink)
            }
            Text(label).font(HubFont.pixel(16, bold: true)).foregroundStyle(.white)
        }
    }

    private var keyName: String {
        switch slot {
        case .confirm: return Copy.keyConfirm
        case .back: return Copy.keyBack
        case .menu: return Copy.keyMenu
        }
    }
}
