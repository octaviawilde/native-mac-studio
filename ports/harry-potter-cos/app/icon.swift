import AppKit
let s: CGFloat = 1024
let img = NSImage(size: NSSize(width: s, height: s))
img.lockFocus()
let r = NSRect(x: 80, y: 80, width: s-160, height: s-160)
let path = NSBezierPath(roundedRect: r, xRadius: 190, yRadius: 190)
NSGradient(colors: [NSColor(red:0.10,green:0.28,blue:0.16,alpha:1), NSColor(red:0.02,green:0.08,blue:0.05,alpha:1)])!.draw(in: path, angle: -90)
NSColor(red:0.85,green:0.68,blue:0.25,alpha:1).setStroke(); path.lineWidth = 22; path.stroke()
func emoji(_ t: String, _ size: CGFloat, _ x: CGFloat, _ y: CGFloat) {
  let a: [NSAttributedString.Key: Any] = [.font: NSFont(name: "Apple Color Emoji", size: size)!]
  NSAttributedString(string: t, attributes: a).draw(at: NSPoint(x: x, y: y))
}
emoji("🐍", 430, 300, 170)
emoji("⚡", 330, 140, 470)
emoji("🪄", 260, 560, 520)
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "icon1024.png"))
