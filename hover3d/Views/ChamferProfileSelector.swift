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

      HStack(spacing: 20) {
        Button {
          profile = .curvedOut
          node.updateChamfer(profile: profile)
        } label: {
          Text("curveOut")
        }

        Button {
          profile = .curvedIn
          node.updateChamfer(profile: profile)
        } label: {
          Text("curveIn")
        }
      }

      HStack(spacing: 20) {
        Button {
          profile = .tildaIn
          node.updateChamfer(profile: profile)
        } label: {
          Text("TildaIn")
        }

        Button {
          profile = .tildaOut
          node.updateChamfer(profile: profile)
        } label: {
          Text("TildaOut")
        }
      }
    }
    .buttonStyle(ChamferButtonStyle())
  }
}

struct ChamferProfileSelector_Previews: PreviewProvider {
  static var previews: some View {
    ChamferProfileSelector(node: SCNNode(), profile: .constant(.straight))
      .padding()
  }
}
