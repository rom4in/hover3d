import SwiftUI

struct SliderRow: View {
  let title: String
  @Binding var value: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.subheadline)
      ValueBubbleSlider(value: percentageValue, accessibilityLabel: title)
    }
  }

  private var percentageValue: Binding<CGFloat> {
    Binding(
      get: { value * 100 },
      set: { value = $0 / 100 }
    )
  }
}
