import SwiftUI
import SceneKit

private struct ChamferButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.caption.weight(.medium))
      .foregroundStyle(.primary)
      .frame(minWidth: 72)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(Color.secondary.opacity(configuration.isPressed ? 0.2 : 0.12))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 6)
          .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
      )
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
  }
}

struct ChamferModeSelector: View {

  var node : SCNNode
  @Binding var mode : SCNChamferMode

  var body: some View {

    VStack(spacing: 20) {

      Button {
        self.mode = .both
        self.node.updateChamfer(mode: self.mode)
      } label: {
        Text("both")
      }

      HStack(spacing: 20) {
        Button {
          self.mode = .front
          self.node.updateChamfer(mode: self.mode)
        } label: {
          Text("front")
        }

        Button {
          self.mode = .back
          self.node.updateChamfer(mode: self.mode)
        } label: {
          Text("back")
        }
      }
    }
    .buttonStyle(ChamferButtonStyle())
  }
}

enum ChamferProfileType  {
  case straight
  case curvedIn
  case curvedOut
  case tildaIn
  case tildaOut

  func getBezierPath() -> NSBezierPath {
    switch self {
      case .straight: return NSBezierPath.straight
      case .curvedIn: return NSBezierPath.curvedIn
      case .curvedOut: return NSBezierPath.curvedOut
      case .tildaIn: return NSBezierPath.tildaIn
      case .tildaOut: return NSBezierPath.tildaOut
    }
  }
}


struct ChamferProfileSelector: View {

  var node : SCNNode
  @Binding var profile : ChamferProfileType

  var body: some View {

      VStack(spacing: 20) {

        Button {
          profile = .straight
          node.updateChamfer(profile: self.profile)
        } label: {
          Text("straight")
        }

        HStack(spacing: 20) {

          Button {
            profile = .curvedOut
            node.updateChamfer(profile: self.profile)
          } label: {
            Text("curveOut")
          }

          Button {
            self.profile = .curvedIn
            self.node.updateChamfer(profile: self.profile)
          } label: {
            Text("curveIn")
          }
        }


        HStack(spacing: 20) {
          Button {
            self.profile = .tildaIn
            self.node.updateChamfer(profile: self.profile)
          } label: {
            Text("TildaIn")
          }

          Button {
            self.profile = .tildaOut
            self.node.updateChamfer(profile: self.profile)
          } label: {
            Text("TildaOut")
          }
        }

        Color.clear

    }
    .buttonStyle(ChamferButtonStyle())

  }
}
