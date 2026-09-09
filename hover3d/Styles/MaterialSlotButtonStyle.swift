import SwiftUI

struct MaterialSlotButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.caption.weight(.medium))
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
      .background(isSelected ? Color.accentColor : Color.textSecondary.opacity(0.12))
      .foregroundColor(isSelected ? .white : .textPrimary)
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .opacity(configuration.isPressed ? 0.75 : 1)
  }
}

#Preview("Material slot buttons") {
  HStack(spacing: 6) {
    Button("Front") {}
      .buttonStyle(MaterialSlotButtonStyle(isSelected: true))

    Button("Back") {}
      .buttonStyle(MaterialSlotButtonStyle(isSelected: false))
  }
  .padding()
}
