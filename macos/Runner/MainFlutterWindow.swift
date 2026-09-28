import Cocoa
import FlutterMacOS
import window_manager
import LaunchAtLogin

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        // FlutterView paints black by default; Veil draws its glass panel over
        // a see-through window, blurred by the backdrop view underneath.
        flutterViewController.backgroundColor = .clear
        self.backgroundColor = .clear
        let windowFrame = self.frame
        let backdropController = BackdropViewController(flutterViewController: flutterViewController)
        self.contentViewController = backdropController
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
            case "setWindowBackdrop":
                // window_manager's setAsFrameless marks the window opaque again.
                guard let window = self else {
                    result("opaque")
                    return
                }
                let args = call.arguments as? [String: Any]
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = false
                backdropController.applyBackdrop(
                    dark: args?["dark"] as? Bool ?? false,
                    radius: CGFloat(args?["radius"] as? Double ?? 26)
                )
                result("backdrop")
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

class BackdropViewController: NSViewController {
    let flutterViewController: FlutterViewController
    private let effectView = NSVisualEffectView()

    init(flutterViewController: FlutterViewController) {
        self.flutterViewController = flutterViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        effectView.autoresizingMask = [.width, .height]
        effectView.blendingMode = .behindWindow
        effectView.material = .popover
        // A floating widget is usually not the key window; keep it frosted.
        effectView.state = .active
        effectView.isHidden = true
        container.addSubview(effectView)
        self.view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(flutterViewController)
        flutterViewController.view.frame = view.bounds
        flutterViewController.view.autoresizingMask = [.width, .height]
        effectView.frame = view.bounds
        view.addSubview(flutterViewController.view, positioned: .above, relativeTo: effectView)
    }

    func applyBackdrop(dark: Bool, radius: CGFloat) {
        effectView.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        effectView.maskImage = radius > 0 ? Self.roundedMask(radius: radius) : nil
        effectView.isHidden = false
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}
