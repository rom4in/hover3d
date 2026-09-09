import SwiftUI
import UniformTypeIdentifiers

struct Editor: View {
    @EnvironmentObject var model: DataModel
    @State private var isDropping = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                svgDropArea
                
                Text("Shape controls")
                    .font(.title3.weight(.semibold))
                
                GroupBox(label: Text("Geometry")) {
                    VStack(alignment: .leading, spacing: 12) {
                        SliderRow(title: "Extrusion", value: Binding(
                            get: { model.extrusion / 100 },
                            set: { value in
                                model.extrusion = value * 100
                                model.mamaNode.updateExtrusion(extrusion: model.extrusion)
                            }
                        ))
                        SliderRow(title: "Layer offset", value: Binding(
                            get: { model.zOffset / 100 },
                            set: { value in
                                model.zOffset = value * 100
                                model.mamaNode.updateZ(offset: model.zOffset)
                            }
                        ))
                    }.padding(.top, 4)
                }
                
                GroupBox(label: Text("Chamfer")) {
                    VStack(alignment: .leading, spacing: 14) {
                        SliderRow(title: "Radius", value: Binding(
                            get: { model.chamferRadius / 16 },
                            set: { value in
                                model.chamferRadius = value * 16
                                model.mamaNode.updateChamfer(radius: model.chamferRadius)
                            }
                        ))
                        Text("Mode").font(.subheadline.weight(.medium))
                        ChamferModeSelector(node: model.mamaNode, mode: $model.chamferMode)
                        Text("Profile").font(.subheadline.weight(.medium))
                        ChamferProfileSelector(node: model.mamaNode, profile: $model.chamferProfile)
                        
                    }.padding(.top, 4)
                }
            }.padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
    
    
    private var svgDropArea: some View {
        Button {
            openSVGFile()
        } label: {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDropping ? Color.accentColor : Color.textSecondary.opacity(0.3),
                                    style: StrokeStyle(lineWidth: isDropping ? 2 : 1, dash: [6]))
                            .allowsHitTesting(false)
                    )
                }
            }
        }
            .padding(.vertical, 4)
            
        .onDrop(of: ["public.file-url"], isTargeted: $isDropping, perform: handleDrop)
        .buttonStyle(.plain)
    }
    func openSVGFile() {
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
        provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, _ in
            guard let data,
                  let path = String(data: data, encoding: .utf8) else { return }
            let url = path.hasPrefix("file://")
            ? URL(string: path)
            : URL(fileURLWithPath: path)
            guard let url else { return }
            DispatchQueue.main.async {
                model.importSVG(from: url)
            }
        }
        return true
    }
    
}

struct Editor_Previews: PreviewProvider {
    static var previews: some View { Editor().environmentObject(DataModel()) }
}
