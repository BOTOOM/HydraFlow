import Flutter
import UIKit

final class FoldRegionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private weak var registrar: FlutterPluginRegistrar?
  private var eventSink: FlutterEventSink?
  private weak var flutterView: UIView?
  private var probe: FoldRegionProbeView?
  private var timer: Timer?
  private var lastPayload: Data?

  static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = FoldRegionPlugin(registrar: registrar)
    let channel = FlutterEventChannel(
      name: "hydraflow/fold_regions",
      binaryMessenger: registrar.messenger()
    )
    channel.setStreamHandler(plugin)
  }

  private init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    guard let view = flutterViewControllerView() else {
      emitEmptyPayload()
      return nil
    }

    flutterView = view
    let probe = FoldRegionProbeView(frame: view.bounds)
    probe.isHidden = true
    probe.isUserInteractionEnabled = false
    probe.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    probe.onLayout = { [weak self] in self?.emitRegions() }
    self.probe = probe
    view.addSubview(probe)
    probe.setNeedsLayout()
    probe.layoutIfNeeded()

    timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) {
      [weak self] _ in
      self?.emitRegions()
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    timer?.invalidate()
    timer = nil
    probe?.removeFromSuperview()
    probe = nil
    flutterView = nil
    eventSink = nil
    lastPayload = nil
    return nil
  }

  private func flutterViewControllerView() -> UIView? {
    if let view = registrar?.viewController?.view {
      return view
    }
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first(where: \.isKeyWindow)?
      .rootViewController?.view
  }

  private func emitRegions() {
    guard let view = flutterView else { return }
    var payload: [String: Any] = ["divisions": [], "occlusions": []]

    if #available(iOS 27.1, *) {
      payload = [
        "divisions": frames(in: view, kind: .division),
        "occlusions": frames(in: view, kind: .occlusion),
      ]
    }

    sendIfChanged(payload)
  }

  @available(iOS 27.1, *)
  private func frames(
    in view: UIView,
    kind: UIView.ReservedRegion.Kind
  ) -> [[String: Double]] {
    view.reservedRegions(kind: kind)
      .filter(\.isActive)
      .map { region in
        let frame = view.convert(region.frame, to: view)
        return [
          "x": Double(frame.origin.x),
          "y": Double(frame.origin.y),
          "width": Double(frame.width),
          "height": Double(frame.height),
        ]
      }
  }

  private func emitEmptyPayload() {
    sendIfChanged(["divisions": [], "occlusions": []])
  }

  private func sendIfChanged(_ payload: [String: Any]) {
    guard let eventSink,
          let data = try? JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
          ),
          data != lastPayload
    else {
      return
    }
    lastPayload = data
    eventSink(payload)
  }
}

private final class FoldRegionProbeView: UIView {
  var onLayout: (() -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?()
  }
}
