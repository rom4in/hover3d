import SwiftUI
import SceneKit

struct ChamferModeSelector: View {
  var node: SCNNode
  @Binding var mode: SCNChamferMode

  var body: some View {
    VStack(spacing: 20) {
      Button {
        mode = .both
        node.updateChamfer(mode: mode)
      } label: {
        Text("both")
      }
      .buttonStyle(ChamferButtonStyle(isSelected: mode == .both))

      HStack(spacing: 20) {
        Button {
          mode = .front
          node.updateChamfer(mode: mode)
        } label: {
          Text("front")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: mode == .front))

        Button {
          mode = .back
          node.updateChamfer(mode: mode)
        } label: {
          Text("back")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: mode == .back))
      }
    }
  }
}

struct ChamferModeSelector_Previews: PreviewProvider {
  static var previews: some View {
    ChamferModeSelector(node: SCNNode(), mode: .constant(.both))
      .padding()
  }
}
