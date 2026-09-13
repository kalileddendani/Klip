import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconSet = root.appendingPathComponent(".build/Klip.iconset")
try? FileManager.default.removeItem(at: iconSet)
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)

let sizes = [16, 32, 128, 256, 512]
for size in sizes {
    for scale in [1, 2] {
        let pixels = size * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        NSColor(calibratedRed: 0.035, green: 0.075, blue: 0.055, alpha: 1).setFill()
        NSBezierPath(
            roundedRect: NSRect(x: 0, y: 0, width: pixels, height: pixels),
            xRadius: CGFloat(pixels) * 0.22, yRadius: CGFloat(pixels) * 0.22
        ).fill()

        let canvas = CGFloat(pixels)
        let paper = NSRect(
            x: canvas * 0.2705, y: canvas * 0.2051, width: canvas * 0.4590, height: canvas * 0.5078)
        NSColor(calibratedRed: 0.961, green: 0.969, blue: 0.965, alpha: 1).setFill()
        NSBezierPath(roundedRect: paper, xRadius: canvas * 0.0469, yRadius: canvas * 0.0469).fill()

        NSColor(calibratedRed: 0.624, green: 0.722, blue: 0.675, alpha: 1).setFill()
        NSBezierPath(
            roundedRect: NSRect(
                x: canvas * 0.3926, y: canvas * 0.1465, width: canvas * 0.2148,
                height: canvas * 0.1172),
            xRadius: canvas * 0.0391, yRadius: canvas * 0.0391
        ).fill()

        // Notch cut into the clip tab, punched out in the background color.
        NSColor(calibratedRed: 0.063, green: 0.125, blue: 0.102, alpha: 1).setFill()
        NSBezierPath(
            roundedRect: NSRect(
                x: canvas * 0.4414, y: canvas * 0.1758, width: canvas * 0.1172,
                height: canvas * 0.0332),
            xRadius: canvas * 0.0166, yRadius: canvas * 0.0166
        ).fill()

        NSColor(calibratedRed: 0.133, green: 0.773, blue: 0.369, alpha: 1).setFill()
        let leaf = NSBezierPath()
        leaf.move(to: NSPoint(x: canvas * 0.5, y: canvas * (1 - 0.6836)))
        leaf.curve(
            to: NSPoint(x: canvas * 0.5, y: canvas * (1 - 0.3418)),
            controlPoint1: NSPoint(x: canvas * 0.3418, y: canvas * (1 - 0.6348)),
            controlPoint2: NSPoint(x: canvas * 0.3418, y: canvas * (1 - 0.4297)))
        leaf.curve(
            to: NSPoint(x: canvas * 0.5, y: canvas * (1 - 0.6836)),
            controlPoint1: NSPoint(x: canvas * 0.6582, y: canvas * (1 - 0.4297)),
            controlPoint2: NSPoint(x: canvas * 0.6582, y: canvas * (1 - 0.6348)))
        leaf.close()
        leaf.fill()

        NSColor(calibratedRed: 0.086, green: 0.396, blue: 0.196, alpha: 1).setStroke()
        let vein = NSBezierPath()
        vein.lineWidth = max(2, canvas * 0.0215)
        vein.lineCapStyle = .round
        vein.move(to: NSPoint(x: canvas * 0.5, y: canvas * (1 - 0.6641)))
        vein.line(to: NSPoint(x: canvas * 0.5, y: canvas * (1 - 0.3711)))
        vein.stroke()
        image.unlockFocus()

        guard let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!),
            let data = bitmap.representation(using: .png, properties: [:])
        else { continue }
        let name = "icon_\(size)x\(size)" + (scale == 2 ? "@2x" : "") + ".png"
        try data.write(to: iconSet.appendingPathComponent(name))
    }
}
