import SwiftUI
import SceneKit

struct ChamferProfileSelector: View {
  var node: SCNNode
  @Binding var profile: ChamferProfileType

  var body: some View {
    VStack(spacing: 20) {
      Button {
        profile = .straight
        node.updateChamfer(profile: profile)
      } label: {
        Text("straight")
      }
      .buttonStyle(ChamferButtonStyle(isSelected: profile == .straight))

      HStack(spacing: 20) {
        Button {
          profile = .curvedOut
          node.updateChamfer(profile: profile)
        } label: {
          Text("curveOut")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .curvedOut))

        Button {
          profile = .curvedIn
          node.updateChamfer(profile: profile)
        } label: {
          Text("curveIn")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .curvedIn))
      }

      HStack(spacing: 20) {
        Button {
          profile = .tildaIn
          node.updateChamfer(profile: profile)
        } label: {
          Text("TildaIn")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .tildaIn))

        Button {
          profile = .tildaOut
          node.updateChamfer(profile: profile)
        } label: {
          Text("TildaOut")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .tildaOut))
      }
    }
  }
}

struct ChamferProfileSelector_Previews: PreviewProvider {
  static var previews: some View {
    ChamferProfileSelector(node: SCNNode(), profile: .constant(.straight))
      .padding()
  }
}
