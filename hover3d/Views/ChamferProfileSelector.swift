import SwiftUI

struct ChamferProfileSelector: View {
  @Binding var profile: ChamferProfileType

  var body: some View {
    VStack(spacing: 20) {
      Button {
        profile = .straight
      } label: {
        Text("straight")
      }
      .buttonStyle(ChamferButtonStyle(isSelected: profile == .straight))

      HStack(spacing: 20) {
        Button {
          profile = .curvedOut
        } label: {
          Text("curveOut")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .curvedOut))

        Button {
          profile = .curvedIn
        } label: {
          Text("curveIn")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .curvedIn))
      }

      HStack(spacing: 20) {
        Button {
          profile = .tildaIn
        } label: {
          Text("TildaIn")
        }
        .buttonStyle(ChamferButtonStyle(isSelected: profile == .tildaIn))

        Button {
          profile = .tildaOut
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
    ChamferProfileSelector(profile: .constant(.straight))
      .padding()
  }
}
