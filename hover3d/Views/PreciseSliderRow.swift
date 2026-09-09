import SwiftUI

struct PreciseSliderRow: View {
  let title: String
  @Binding var value: CGFloat

  private static let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimum = 0
    formatter.maximum = 1
    formatter.maximumFractionDigits = 4
    formatter.minimumFractionDigits = 0
    formatter.allowsFloats = true
    return formatter
  }()

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(title).font(.subheadline)
        Spacer()
        TextField("0.0", value: $value, formatter: Self.formatter)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 70)
      }
      Slider(value: $value, in: 0...1)
    }
  }
}
