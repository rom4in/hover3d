import Foundation
import SwiftUI

struct ValueBubbleSlider: View {
    @Binding private var value: CGFloat
    private let range: ClosedRange<CGFloat>
    private let accessibilityLabel: String
    
    @Environment(\.isEnabled) private var isEnabled
    
    private let trackHeight: CGFloat = 40
    private let valueBadgeDiameter: CGFloat = 30
    
    private let fillColor = Color.accentColor
    private let trackColor = Color.textPrimary.opacity(0.14)
    private let valueBadgeColor = Color.backgroundPrimary.opacity(0.2)
    
    init(
        value: Binding<CGFloat>,
        in range: ClosedRange<CGFloat> = 0...100,
        accessibilityLabel: String
    ) {
        _value = value
        self.range = range
        self.accessibilityLabel = accessibilityLabel
    }
    
    var body: some View {
        GeometryReader { proxy in
            let valueBadgePosition = valueBadgePosition(in: proxy.size.width)
            let fillWidth = fillWidth(for: valueBadgePosition, in: proxy.size.width)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor.opacity(isEnabled ? 1 : 0.55))
                    .frame(height: trackHeight)
                
                Capsule()
                    .fill(fillColor.opacity(isEnabled ? 1 : 0.45))
                    .frame(width: fillWidth, height: trackHeight)
                
                valueLabel
                    .position(x: valueBadgePosition, y: proxy.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(in: proxy.size.width))
        }
        .frame(height: trackHeight)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(formattedValue)
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) / 100
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }
    
    private var valueLabel: some View {
        Text(formattedValue)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.primary)
            .frame(width: valueBadgeDiameter, height: valueBadgeDiameter)
            .background(Circle().fill(valueBadgeColor.opacity(isEnabled ? 1 : 0.45)))
    }
    
    private var formattedValue: String {
        String(Int(value.rounded()))
    }
    
    private func fillWidth(for valueBadgePosition: CGFloat, in width: CGFloat) -> CGFloat {
        min(width, valueBadgePosition + trackHeight / 2)
    }
    
    private func valueBadgePosition(in width: CGFloat) -> CGFloat {
        let minimumPosition = trackHeight / 2
        let availableWidth = max(0, width - trackHeight)
        return minimumPosition + progress * availableWidth
    }
    
    private var progress: CGFloat {
        guard range.upperBound > range.lowerBound else { return 0 }
        return min(1, max(0, (value - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }
    
    private func dragGesture(in width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                guard isEnabled else { return }
                let availableWidth = width - trackHeight
                guard availableWidth > 0 else { return }
                let normalizedPosition = min(1, max(0, (gesture.location.x - trackHeight / 2) / availableWidth))
                value = (range.lowerBound + normalizedPosition * (range.upperBound - range.lowerBound)).rounded()
            }
    }
}

#Preview {
    @Previewable @State var value: CGFloat = 71
    
    ValueBubbleSlider(value: $value, accessibilityLabel: "Metallic")
        .frame(width: 360)
        .padding()
}
