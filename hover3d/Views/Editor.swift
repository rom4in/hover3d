import SwiftUI
import SceneKit
import UniformTypeIdentifiers

struct Editor: View {
    @EnvironmentObject var model: DataModel
    @State private var isDropping = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            svgDropArea
            
            ScrollView(showsIndicators: false) {
                geometriesList
                selectedGeometryControls
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
    
    private var geometriesList: some View {
        GroupBox {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(model.geometryNodes.enumerated()), id: \.offset) { _, node in
                        geometryButton(for: node)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(.upArrow, phases: .down) { keyPress in
                model.moveSelection(by: -1, extendingSelection: keyPress.modifiers.contains(.shift))
                return .handled
            }
            .onKeyPress(.downArrow, phases: .down) { keyPress in
                model.moveSelection(by: 1, extendingSelection: keyPress.modifiers.contains(.shift))
                return .handled
            }
        }
    }
    
    private func geometryButton(for node: SCNNode) -> some View {
        Button {
            model.select(node: node, extendingSelection: NSEvent.modifierFlags.contains(.shift))
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "cube")
                    .foregroundColor(.textSecondary)
                Text(node.name ?? "Geometry")
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(model.selectedGeometryNodes.contains(where: { $0 === node }) ? Color.accentColor.opacity(0.18) : .clear)
            )
        }
        .buttonStyle(.plain)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.upArrow, phases: .down) { keyPress in
            model.moveSelection(by: -1, extendingSelection: keyPress.modifiers.contains(.shift))
            return .handled
        }
        .onKeyPress(.downArrow, phases: .down) { keyPress in
            model.moveSelection(by: 1, extendingSelection: keyPress.modifiers.contains(.shift))
            return .handled
        }
    }
    
    @ViewBuilder
    private var selectedGeometryControls: some View {
        if model.selectedGeometrySettings != nil {
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    SliderRow(title: "Chamfer radius", value: chamferRadiusBinding)
                    SliderRow(title: "Extrusion", value: extrusionBinding)
                    SliderRow(title: "Layer offset", value: layerOffsetBinding, range: -100...100)
                    Text("Mode").font(.subheadline.weight(.medium))
                    ChamferModeSelector(mode: chamferModeBinding)
                    Text("Profile").font(.subheadline.weight(.medium))
                    ChamferProfileSelector(profile: chamferProfileBinding)
                }
                .padding(.top, 4)
            }
        }
    }

    private var selectedGeometryTitle: String {
        guard let selected = model.selectedGeometryNode else { return "Geometry" }
        let count = model.selectedGeometryNodes.count
        return count > 1 ? "\(count) Geometries (primary: \(selected.name ?? "Geometry"))" : (selected.name ?? "Geometry")
    }

    private var chamferRadiusBinding: Binding<CGFloat> {
        Binding(
            get: { (model.selectedGeometrySettings?.chamferRadius ?? 0) / 10 },
            set: { model.updateSelectedChamferRadius($0 * 10) }
        )
    }
    
    private var extrusionBinding: Binding<CGFloat> {
        Binding(
            get: { (model.selectedGeometrySettings?.extrusion ?? 0) / 100 },
            set: { model.updateSelectedExtrusion($0 * 100) }
        )
    }
    
    private var layerOffsetBinding: Binding<CGFloat> {
        Binding(
            get: { (model.selectedGeometrySettings?.layerOffset ?? 0) / 100 },
            set: { model.updateSelectedLayerOffset($0 * 100) }
        )
    }
    
    private var chamferModeBinding: Binding<SCNChamferMode> {
        Binding(
            get: { model.selectedGeometrySettings?.chamferMode ?? .front },
            set: { model.updateSelectedChamferMode($0) }
        )
    }
    
    private var chamferProfileBinding: Binding<ChamferProfileType> {
        Binding(
            get: { model.selectedGeometrySettings?.chamferProfile ?? .curvedOut },
            set: { model.updateSelectedChamferProfile($0) }
        )
    }
    
    private var svgDropArea: some View {
        Button(action: openSVGFile) {
            VStack(spacing: 10) {
                if let image = model.importedSVGImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 130)
                        .background(Color.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(model.fileName)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                } else {
                    VStack {
                        Image(systemName: "arrow.down.doc")
                            .font(.title2)
                            .foregroundColor(.textSecondary)
                        Text("Drop an SVG here")
                            .font(.subheadline.weight(.medium))
                        Text("or click to choose a file")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .contentShape(.rect)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isDropping ? Color.accentColor : Color.textSecondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: isDropping ? 2 : 1, dash: [6])
                            )
                            .allowsHitTesting(false)
                    )
                }
            }
        }
        .padding(.vertical, 4)
        .onDrop(of: ["public.file-url"], isTargeted: $isDropping, perform: handleDrop)
        .buttonStyle(.plain)
    }
    
    private func openSVGFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.svg]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.importSVG(from: url)
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { [model] data, _ in
            guard let data,
                  let path = String(data: data, encoding: .utf8) else { return }
            let url = path.hasPrefix("file://") ? URL(string: path) : URL(fileURLWithPath: path)
            guard let url else { return }
            Task { @MainActor in model.importSVG(from: url) }
        }
        return true
    }
    
}

#Preview {
    Editor()
        .environmentObject(DataModel())
}
