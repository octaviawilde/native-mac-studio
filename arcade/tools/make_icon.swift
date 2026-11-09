// Draws Arcade's 1024px icon: a glossy pink tile with a dripping "A" and a sparkle.
// Usage: swift make_icon.swift <RubikWetPaint.ttf> <out.png>
import AppKit
import CoreText

let args = CommandLine.arguments
CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: args[1]) as CFURL, .process, nil)
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

// Chrome rim behind the tile, then the tile with a gloss across its top half.
NSGradient(colors: [.white, NSColor(red: 0.8, green: 0.78, blue: 0.92, alpha: 1), .white,
                    NSColor(red: 0.98, green: 0.7, blue: 0.88, alpha: 1)])!
    .draw(in: NSBezierPath(roundedRect: tile.insetBy(dx: -13, dy: -13), xRadius: 198, yRadius: 198), angle: 45)
NSGradient(colors: [NSColor(red: 1.0, green: 0.62, blue: 0.84, alpha: 1),
                    NSColor(red: 1.0, green: 0.18, blue: 0.58, alpha: 1),
                    NSColor(red: 0.32, green: 0.04, blue: 0.30, alpha: 1)])!.draw(in: shape, angle: -90)
NSGraphicsContext.saveGraphicsState()
shape.addClip()
NSGradient(colors: [NSColor.white.withAlphaComponent(0.55), NSColor.white.withAlphaComponent(0)])!
    .draw(in: NSRect(x: tile.minX, y: tile.midY, width: tile.width, height: tile.height / 2), angle: -90)
NSGraphicsContext.restoreGraphicsState()

// The dripping "A".
let font = NSFont(name: "RubikWetPaint-Regular", size: 640)!
let shadow = NSShadow()
shadow.shadowColor = NSColor(red: 0.45, green: 0, blue: 0.05, alpha: 1)
shadow.shadowOffset = NSSize(width: 14, height: -14)
let letter = NSAttributedString(string: "A", attributes: [
    .font: font, .foregroundColor: NSColor(red: 0.78, green: 0.02, blue: 0.10, alpha: 1), .shadow: shadow,
    .strokeColor: NSColor.white, .strokeWidth: -3.5])
let ls = letter.size()
letter.draw(at: NSPoint(x: (size - ls.width) / 2, y: (size - ls.height) / 2 - 20))

// Sparkle top right.
func sparkle(_ c: NSPoint, _ r: CGFloat) {
    let p = NSBezierPath(), k: CGFloat = 0.18
    p.move(to: NSPoint(x: c.x, y: c.y + r))
    p.curve(to: NSPoint(x: c.x + r, y: c.y), controlPoint1: NSPoint(x: c.x + r * k, y: c.y + r * k), controlPoint2: NSPoint(x: c.x + r * k, y: c.y + r * k))
    p.curve(to: NSPoint(x: c.x, y: c.y - r), controlPoint1: NSPoint(x: c.x + r * k, y: c.y - r * k), controlPoint2: NSPoint(x: c.x + r * k, y: c.y - r * k))
    p.curve(to: NSPoint(x: c.x - r, y: c.y), controlPoint1: NSPoint(x: c.x - r * k, y: c.y - r * k), controlPoint2: NSPoint(x: c.x - r * k, y: c.y - r * k))
    p.curve(to: NSPoint(x: c.x, y: c.y + r), controlPoint1: NSPoint(x: c.x - r * k, y: c.y + r * k), controlPoint2: NSPoint(x: c.x - r * k, y: c.y + r * k))
    NSColor.white.setFill(); p.fill()
}
sparkle(NSPoint(x: 770, y: 770), 80)
sparkle(NSPoint(x: 262, y: 300), 38)

image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
