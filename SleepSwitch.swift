import AppKit

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    let toggle = NSMenuItem(title: "Prevent Sleep", action: #selector(toggleSleep), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        toggle.target = self
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        status.menu = menu
        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) { refresh() }

    func pmset(_ arguments: [String], asRoot: Bool = false) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: asRoot ? "/usr/bin/sudo" : "/usr/bin/pmset")
        process.arguments = (asRoot ? ["-n", "/usr/bin/pmset"] : []) + arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "SleepSwitch", code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "pmset failed." : output])
        }
        return output
    }

    func sleepDisabled() throws -> Bool {
        let output = try pmset(["-g"])
        let fields = output.split(separator: "\n")
            .map { $0.split(whereSeparator: { $0.isWhitespace }) }
            .first { $0.first == "SleepDisabled" }
        guard let fields, fields.count == 2,
              fields[1] == "0" || fields[1] == "1" else {
            throw NSError(domain: "SleepSwitch", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not read pmset's SleepDisabled setting."])
        }
        return fields[1] == "1"
    }

    func refresh() {
        do {
            let disabled = try sleepDisabled()
            toggle.isEnabled = true
            toggle.state = disabled ? .on : .off
            status.button?.image = NSImage(systemSymbolName: disabled ? "cup.and.saucer.fill" : "cup.and.saucer", accessibilityDescription: "Prevent Sleep")
            status.button?.toolTip = disabled ? "Sleep prevention is on" : "Sleep prevention is off"
        } catch {
            toggle.isEnabled = false
            toggle.state = .off
            status.button?.image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Sleep setting unavailable")
            status.button?.toolTip = error.localizedDescription
        }
    }

    @objc func toggleSleep() {
        do {
            let value = try sleepDisabled() ? "0" : "1"
            _ = try pmset(["disablesleep", value], asRoot: true)
        } catch {
            showError(error.localizedDescription)
        }
        refresh()
    }

    func showError(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Could not change sleep"
        alert.informativeText = message
        alert.runModal()
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
