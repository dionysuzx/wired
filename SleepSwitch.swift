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

    func sleepDisabled() throws -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = pipe
        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        let fields = output.split(separator: "\n")
            .map { $0.split(whereSeparator: { $0.isWhitespace }) }
            .first { $0.first == "SleepDisabled" }
        guard process.terminationStatus == 0, let fields, fields.count == 2,
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
            status.button?.image = NSImage(systemSymbolName: disabled ? "cup.and.saucer.fill" : "moon.zzz", accessibilityDescription: "Prevent Sleep")
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
            let value = try sleepDisabled() ? 0 : 1
            let script = NSAppleScript(source: "do shell script \"/usr/bin/pmset disablesleep \(value)\" with administrator privileges")!
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error, error[NSAppleScript.errorNumber] as? Int != -128 {
                showError(error[NSAppleScript.errorMessage] as? String ?? "Could not change the sleep setting.")
            }
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
