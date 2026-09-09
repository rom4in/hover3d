import SwiftUI
import SceneKit

struct HoverView : NSViewRepresentable {

  @Binding var sceneView : SCNView
  let model: DataModel

  func makeNSView(context: Context) -> SCNView {

    sceneView.allowsCameraControl = true
    sceneView.autoenablesDefaultLighting = true
    sceneView.isJitteringEnabled = true
    sceneView.defaultCameraController.inertiaFriction = 0.18
    sceneView.antialiasingMode = .multisampling4X
    sceneView.backgroundColor = .windowBackgroundColor
    let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.selectSurface(_:)))
    sceneView.addGestureRecognizer(click)

    return sceneView
  }
  func updateNSView(_ view: SCNView, context: Context) {
  }

  func makeCoordinator() -> Coordinator { Coordinator(model: model) }

  final class Coordinator: NSObject {
    let model: DataModel

    init(model: DataModel) { self.model = model }

    @objc func selectSurface(_ recognizer: NSClickGestureRecognizer) {
      guard let view = recognizer.view as? SCNView else { return }
      let point = recognizer.location(in: view)
      guard let hit = view.hitTest(point, options: [.searchMode: SCNHitTestSearchMode.closest.rawValue]).first else { return }

      let normal = hit.localNormal
      let materialIndex: Int
      if abs(normal.z) > 0.9 {
        materialIndex = normal.z >= 0 ? 0 : 1
      } else if abs(normal.z) > 0.05 {
        materialIndex = 3
      } else {
        materialIndex = 2
      }
      model.select(node: hit.node, material: materialIndex)
    }
  }
}
