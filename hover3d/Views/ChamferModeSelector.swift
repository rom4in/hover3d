import SwiftUI
import SceneKit

struct ChamferModeSelector: View {
  @Binding var mode: SCNChamferMode

  var body: some View {
    VStack(spacing: 20) {
      Button {
        mode = .both
      } label: {
        Text("both")
      }
      .buttonStyle(ChamferButtonStyle(isSelected: mode == .both))

      HStack(spacing: 20) {
        Button {
          mode = .front
        } label: {
          Text("front")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: mode == .front))

        Button {
          mode = .back
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
    ChamferModeSelector(mode: .constant(.both))
      .padding()
  }
}
