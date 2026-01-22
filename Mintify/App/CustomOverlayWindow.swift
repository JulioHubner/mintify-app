import AppKit

/// Custom Window to allow key status and borderless behavior for menu bar overlay
class CustomOverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
