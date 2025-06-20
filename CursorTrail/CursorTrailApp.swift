import SwiftUI
import Cocoa
import AppKit

@main
struct CursorTrailApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: AlwaysVisiblePanel!
    var timer: Timer?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        createOverlayWindow()
        startTrackingCursor()
        setupStatusItem()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.overlayWindow.orderFrontRegardless()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSpaceSwitch),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    func createOverlayWindow() {
        // 🔵 Larger circle around the system cursor
        let circleSize: CGFloat = 32
        let lineWidth: CGFloat = 1.5

        let circleView = NSHostingView(rootView:
            Circle()
                .stroke(Color.blue.opacity(0.7), lineWidth: lineWidth)
                .frame(width: circleSize, height: circleSize)
        )

        overlayWindow = AlwaysVisiblePanel(
            contentRect: CGRect(origin: .zero, size: CGSize(width: circleSize, height: circleSize)),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        overlayWindow.contentView = circleView
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary
        ]

        overlayWindow.setIsVisible(true)
        overlayWindow.orderFrontRegardless()
    }

    func startTrackingCursor() {
        let radius: CGFloat = 16 // half of 32

        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            let mouseLocation = NSEvent.mouseLocation
            let newOrigin = CGPoint(x: mouseLocation.x - radius, y: mouseLocation.y - radius)
            self.overlayWindow.setFrameOrigin(newOrigin)
        }
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Cursor Outline")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Trail", action: #selector(toggleTrail), keyEquivalent: "t"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit CursorTrail", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func toggleTrail() {
        if overlayWindow.isVisible {
            overlayWindow.orderOut(nil)
        } else {
            overlayWindow.orderFrontRegardless()
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    @objc func handleSpaceSwitch() {
        for delay in [0.05, 0.2, 0.4, 0.6] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.overlayWindow.orderFrontRegardless()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - Always Visible Panel

class AlwaysVisiblePanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override init(contentRect: NSRect,
                  styleMask: NSWindow.StyleMask,
                  backing: NSWindow.BackingStoreType,
                  defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: styleMask, backing: backing, defer: flag)
        self.worksWhenModal = true
        self.hidesOnDeactivate = false
        self.isReleasedWhenClosed = false
    }
}
