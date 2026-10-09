import AppKit
import IOKit.ps
import notify

@main
@MainActor
final class Wired: NSObject, NSApplicationDelegate {
    let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        status.menu = menu

        var token: Int32 = 0
        let result = notify_register_dispatch(kIOPSNotifyPowerSource, &token, .main) { [weak self] _ in
            self?.updatePower()
        }
        guard result == NOTIFY_STATUS_OK else {
            showError("Could not watch power-source changes.")
            return
        }
        updatePower()
    }

    func updatePower() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let source = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() else {
            showError("Could not read the power source.")
            return
        }
        let disabled = (source as String) == kIOPMACPowerKey
        do {
            try setSleepDisabled(disabled)
            status.button?.image = NSImage(systemSymbolName: disabled ? "cup.and.saucer.fill" : "cup.and.saucer", accessibilityDescription: "wired")
            status.button?.toolTip = disabled ? "On external power: sleep disabled" : "On battery/UPS: sleep allowed"
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
