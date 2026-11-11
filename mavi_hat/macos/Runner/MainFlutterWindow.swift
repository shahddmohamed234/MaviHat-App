import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.title = "MaviHat • İstanbul Ulaşım"
    self.minSize = NSSize(width: 400, height: 720)
    let defaultSize = NSSize(width: 450, height: 880)
    self.setContentSize(defaultSize)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
