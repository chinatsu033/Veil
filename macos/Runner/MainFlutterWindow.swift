import Cocoa
import FlutterMacOS
import window_manager
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        // FlutterView paints black by default; Veil draws floating glass cards
        // over a see-through window, as it does on Windows.
        flutterViewController.backgroundColor = .clear
        self.backgroundColor = .clear
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        FlutterMethodChannel(
            name: "launch_at_startup", binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        .setMethodCallHandler { (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "launchAtStartupIsEnabled":
                result(LaunchAtLogin.isEnabled)
            case "launchAtStartupSetEnabled":
                if let arguments = call.arguments as? [String: Any] {
                    LaunchAtLogin.isEnabled = arguments["setEnabledValue"] as! Bool
                }
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        FlutterMethodChannel(
            name: "com.follow.clash/app", binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        .setMethodCallHandler { [weak self] (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "setWindowTransparent":
                // window_manager's setAsFrameless marks the window opaque again.
                guard let window = self else {
                    result(false)
                    return
                }
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = false
                result(true)
            case "setDockIcon":
                let path = (call.arguments as? [String: Any])?["path"] as? String
                NSApp.applicationIconImage = path.flatMap { NSImage(contentsOfFile: $0) }
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
    }
    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
        hiddenWindowAtLaunch()
    }
}
