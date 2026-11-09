import AppKit
import GameController

/// What the user asked for, whatever they pressed it on.
enum HubAction { case left, right, up, down, confirm, back, menu }

/// The kind of device used last, so on-screen prompts match what is in the player's hands.
enum InputDevice: Equatable {
    case keyboard
    case controller(name: String, confirm: String, back: String, menu: String)  // SF Symbol names

    var isKeyboard: Bool { if case .keyboard = self { return true }; return false }
}

/// Merges every controller (Xbox, PlayStation, Switch Pro, Joy-Cons, MFi, generic HID) and the
/// keyboard into one stream of HubActions. Buttons are read by position, the way macOS maps
/// them: the bottom face button confirms and the right one goes back, on every controller.
final class InputHub: ObservableObject {
    @Published private(set) var device: InputDevice = .keyboard
    var onAction: ((HubAction) -> Void)?

    private var timer: Timer?
    private var keyMonitor: Any?
    private var held: [ObjectIdentifier: ControllerState] = [:]

    private struct ControllerState {
        var direction: HubAction?
        var nextRepeat: TimeInterval = 0
        var confirm = false, back = false, menu = false
    }

    private static let repeatDelay = 0.38, repeatRate = 0.13, stickThreshold: Float = 0.55

    func start() {
        GCController.shouldMonitorBackgroundEvents = false  // games own the pad while they run
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) {
            [weak self] note in
            if let pad = note.object as? GCController { self?.useController(pad) }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let action = Self.action(forKey: event) else { return event }
            self.device = .keyboard
            if !event.isARepeat || [.left, .right, .up, .down].contains(action) { self.onAction?(action) }
            return nil
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.poll() }
    }

    private static func action(forKey event: NSEvent) -> HubAction? {
        switch event.keyCode {
        case 123, 0: return .left          // ←, A
        case 124, 2: return .right         // →, D
        case 126, 13: return .up           // ↑, W
        case 125, 1: return .down          // ↓, S
        case 36, 76, 49: return .confirm   // Return, keypad Enter, Space
        case 53, 51: return .back          // Esc, Delete
        case 3, 48: return .menu           // F, Tab
        default: return nil
        }
    }

    private func useController(_ pad: GCController) {
        if let g = pad.extendedGamepad {
            device = .controller(name: pad.vendorName ?? "Controller",
                                 confirm: g.buttonA.sfSymbolsName ?? "a.circle",
                                 back: g.buttonB.sfSymbolsName ?? "b.circle",
                                 menu: g.buttonMenu.sfSymbolsName ?? "line.3.horizontal.circle")
        } else if let m = pad.microGamepad {  // a single sideways Joy-Con, a remote
            device = .controller(name: pad.vendorName ?? "Controller",
                                 confirm: m.buttonA.sfSymbolsName ?? "a.circle",
                                 back: m.buttonX.sfSymbolsName ?? "x.circle",
                                 menu: m.buttonMenu.sfSymbolsName ?? "line.3.horizontal.circle")
        }
    }

    private func poll() {
        guard NSApp.isActive else { return }
        let now = ProcessInfo.processInfo.systemUptime
        for pad in GCController.controllers() {
            var dpadX: Float = 0, dpadY: Float = 0, confirm = false, back = false, menu = false
            if let g = pad.extendedGamepad {
                dpadX = abs(g.dpad.xAxis.value) > abs(g.leftThumbstick.xAxis.value) ? g.dpad.xAxis.value : g.leftThumbstick.xAxis.value
                dpadY = abs(g.dpad.yAxis.value) > abs(g.leftThumbstick.yAxis.value) ? g.dpad.yAxis.value : g.leftThumbstick.yAxis.value
                confirm = g.buttonA.isPressed
                back = g.buttonB.isPressed
                menu = g.buttonMenu.isPressed || (g.buttonOptions?.isPressed ?? false)
            } else if let m = pad.microGamepad {
                m.reportsAbsoluteDpadValues = true
                dpadX = m.dpad.xAxis.value; dpadY = m.dpad.yAxis.value
                confirm = m.buttonA.isPressed
                back = m.buttonX.isPressed
                menu = m.buttonMenu.isPressed
            } else { continue }

            var direction: HubAction?
            if abs(dpadX) >= Self.stickThreshold || abs(dpadY) >= Self.stickThreshold {
                direction = abs(dpadX) >= abs(dpadY) ? (dpadX < 0 ? .left : .right) : (dpadY > 0 ? .up : .down)
            }

            let key = ObjectIdentifier(pad)
            var state = held[key] ?? ControllerState()
            if direction != state.direction {
                state.direction = direction
                if let direction { fire(direction, from: pad); state.nextRepeat = now + Self.repeatDelay }
            } else if let direction, now >= state.nextRepeat {
                fire(direction, from: pad); state.nextRepeat = now + Self.repeatRate
            }
            if confirm && !state.confirm { fire(.confirm, from: pad) }
            if back && !state.back { fire(.back, from: pad) }
            if menu && !state.menu { fire(.menu, from: pad) }
            state.confirm = confirm; state.back = back; state.menu = menu
            held[key] = state
        }
    }

    private func fire(_ action: HubAction, from pad: GCController) {
        useController(pad)
        onAction?(action)
    }
}
