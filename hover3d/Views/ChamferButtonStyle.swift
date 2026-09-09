import SwiftUI

struct ChamferButtonStyle: ButtonStyle {
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
