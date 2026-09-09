import SwiftUI
import UniformTypeIdentifiers

struct Editor: View {
  @EnvironmentObject var model: DataModel
  @State private var isDropping = false

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 18) {
        GroupBox(label: Text("SVG")) {
          VStack(spacing: 10) {
            if let image = model.importedSVGImage {
              Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 130)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
              Text(model.fileName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            } else {
              Image(systemName: "arrow.down.doc")
                .font(.title2)
                .foregroundColor(.secondary)
              Text("Drop an SVG here")
                .font(.subheadline.weight(.medium))
              Text("or choose a file below")
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Button(action: openSVGFile) {
              Label("Choose SVG", systemImage: "folder")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
          }
          .padding(.vertical, 4)
        }
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(isDropping ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: isDropping ? 2 : 1, dash: [6]))
            .allowsHitTesting(false)
        )
        .onDrop(of: ["public.file-url"], isTargeted: $isDropping, perform: handleDrop)

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
            Text("Mode").font(.subheadline.weight(.medium))
            ChamferModeSelector(node: model.mamaNode, mode: $model.chamferMode)
            Text("Profile").font(.subheadline.weight(.medium))
            ChamferProfileSelector(node: model.mamaNode, profile: $model.chamferProfile)
            SliderRow(title: "Radius", value: Binding(
              get: { model.chamferRadius / 16 },
              set: { value in
                model.chamferRadius = value * 16
                model.mamaNode.updateChamfer(radius: model.chamferRadius)
              }
            ))
          }.padding(.top, 4)
        }
      }.padding(16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
