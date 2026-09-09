import SwiftUI

struct SliderRow: View {
  let title: String
  @Binding var value: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.subheadline)
      Slider(value: $value)
    }
  }
}
