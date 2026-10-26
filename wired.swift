import AppKit
import IOKit.ps
import notify

@main
@MainActor
final class Wired: NSObject, NSApplicationDelegate {
    let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let menu = NSMenu()
    var override = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        status.button?.target = self
        status.button?.action = #selector(click(_:))
        status.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        var token: Int32 = 0
        let result = notify_register_dispatch(kIOPSNotifyPowerSource, &token, .main) { [weak self] _ in
            self?.override = false
            self?.updatePower()
        }
        guard result == NOTIFY_STATUS_OK else {
            showError("Could not watch power-source changes.")
            return
        }
        updatePower()
    }

    @objc func click(_ button: NSStatusBarButton) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            override.toggle()
            updatePower()
        } else {
            let bottom = button.isFlipped ? button.bounds.maxY : button.bounds.minY
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: bottom), in: button)
        }
    }

    func updatePower() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let source = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() else {
            showError("Could not read the power source.")
            return
        }
        let wired = (source as String) == kIOPMACPowerKey
        let disabled = wired || override
        do {
            try setSleepDisabled(disabled)
            status.button?.image = NSImage(systemSymbolName: disabled ? "cup.and.saucer.fill" : "cup.and.saucer", accessibilityDescription: "wired")
            status.button?.toolTip = wired ? "On external power: sleep disabled"
                : override ? "Manually overridden: sleep disabled" : "On battery/UPS: sleep allowed"
        } catch {
            showError(error.localizedDescription)
        }
    }

    func setSleepDisabled(_ disabled: Bool) throws {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", "/usr/bin/pmset", "disablesleep", disabled ? "1" : "0"]
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "wired", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "pmset failed." : output])
        }
    }

    func showError(_ message: String) {
        status.button?.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "wired error")
        status.button?.toolTip = message
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = Wired()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
