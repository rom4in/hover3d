import SwiftUI

struct ChamferButtonStyle: ButtonStyle {
  var isSelected = false

  func makeBody(configuration: Configuration) -> some View {
    HoverableButton(configuration: configuration, isSelected: isSelected)
  }

  private struct HoverableButton: View {
    let configuration: ButtonStyleConfiguration
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
      configuration.label
        .font(.caption.weight(.medium))
        .foregroundStyle(isSelected ? Color.white : Color.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? Color.accentColor : Color.textSecondary.opacity(backgroundOpacity))
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
