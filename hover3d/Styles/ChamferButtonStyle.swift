import SwiftUI

struct ChamferButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HoverableButton(configuration: configuration)
  }

  private struct HoverableButton: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false

    var body: some View {
      configuration.label
        .font(.caption.weight(.medium))
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(backgroundOpacity))
        )
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var backgroundOpacity: Double {
      if configuration.isPressed {
        return 0.2
      }
      return isHovered ? 0.16 : 0.12
    }
  }
}

#Preview {
    Button {
    } label: {
        Text("front & back")
    }
    .buttonStyle(ChamferButtonStyle())
    .padding(50)
}
