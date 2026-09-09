//
//  Editor.swift
//  hover3d
//

import SwiftUI
import SceneKit
import UniformTypeIdentifiers

private enum ExportFormat: String, CaseIterable, Identifiable {
  case scn
  case usdz
  case usd
  case dae
  case obj
  case stl
  case ply
  case abc

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .scn: return "SceneKit"
    case .usdz: return "USDZ"
    case .usd: return "USD"
    case .dae: return "Collada"
    case .obj: return "OBJ"
    case .stl: return "STL"
    case .ply: return "PLY"
    case .abc: return "Alembic"
    }
  }

  var fileExtension: String { rawValue }

  var contentType: UTType {
    UTType(filenameExtension: fileExtension) ?? .data
  }

  var summary: String {
    switch self {
    case .scn: return "Editable SceneKit scene"
    case .usdz: return "AR Quick Look and spatial apps"
    case .usd: return "Universal Scene Description"
    case .dae: return "Broad 3D app compatibility"
    case .obj: return "Widely supported mesh format"
    case .stl: return "3D printing; geometry only"
    case .ply: return "Mesh data; useful for fabrication tools"
    case .abc: return "VFX and DCC pipelines"
    }
  }
}

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

struct MaterialPanel: View {
  @EnvironmentObject var model: DataModel
  @State private var isSharing = false
  @State private var shareURL: URL?
  @State private var selectedExportFormat: ExportFormat = .scn

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        if model.materialPanelExpanded {
          Text("Material").font(.title3.weight(.semibold))
          Spacer()
        }
        Button {
          withAnimation(.easeInOut(duration: 0.2)) {
            model.materialPanelExpanded.toggle()
          }
        } label: {
          Image(systemName: model.materialPanelExpanded ? "chevron.right" : "chevron.left")
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .help(model.materialPanelExpanded ? "Collapse materials" : "Expand materials")
      }

      if model.materialPanelExpanded {
        materialControls
      }
      Spacer()
      if model.materialPanelExpanded {
        exportControls
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(Color(NSColor.windowBackgroundColor))
    .overlay(
      ShareMenu(isPresented: $isSharing, sharingItems: shareItems)
        .allowsHitTesting(isSharing)
    )
  }

  private var shareItems: [Any] {
    guard let shareURL else { return [] }
    return [shareURL]
  }

  @ViewBuilder
  private var materialControls: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(model.selectedGeometryNode?.name ?? "Click a shape to select it")
        .font(.caption)
        .foregroundColor(.secondary)

      HStack(spacing: 6) {
        ForEach(Array(DataModel.materialNames.enumerated()), id: \.offset) { index, name in
          Button(name.capitalized) { model.selectMaterial(index) }
            .buttonStyle(MaterialSlotButtonStyle(isSelected: model.selectedMaterialIndex == index))
        }
      }

      ColorPicker("Diffuse", selection: Binding(
        get: { model.diffuseColor },
        set: { model.setDiffuseColor($0) }
      ))
      .disabled(model.selectedGeometryNode == nil)

      HStack {
        Button(action: openDiffuseImage) {
          Label(model.materialImageName ?? "Choose image", systemImage: "photo")
        }
        if model.materialImageName != nil {
          Button("Remove") { model.clearDiffuseImage() }
        }
      }
      .disabled(model.selectedGeometryNode == nil)

      PreciseSliderRow(title: "Metallic", value: Binding(
        get: { model.metalness },
        set: { model.updateSelectedMetalness($0) }
      ))
      .disabled(model.selectedGeometryNode == nil)
      PreciseSliderRow(title: "Roughness", value: Binding(
        get: { model.roughness },
        set: { model.updateSelectedRoughness($0) }
      ))
      .disabled(model.selectedGeometryNode == nil)
    }
  }

  @ViewBuilder
  private var exportControls: some View {
    GroupBox(label: Text("Export")) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 6) {
          TextField("Scene name", text: $model.fileName)
            .textFieldStyle(.roundedBorder)
          Text(".\(selectedExportFormat.fileExtension)").foregroundColor(.secondary)
        }
        HStack {
          Text("Format")
          Spacer()
          Picker("Format", selection: $selectedExportFormat) {
            ForEach(ExportFormat.allCases) { format in
              Text("\(format.displayName) (.\(format.fileExtension))")
                .tag(format)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
        }
        Text(selectedExportFormat.summary)
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        HStack {
          Button(action: exportSelectedFormat) {
            Label("Save \(selectedExportFormat.displayName)", systemImage: "square.and.arrow.down")
          }
          Button(action: shareScene) {
            Label("Share", systemImage: "square.and.arrow.up.on.square")
          }
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
      }
    }
    .padding(.top, 4)
  }

  private func openDiffuseImage() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedContentTypes = ["png", "jpg", "jpeg", "tiff", "tif", "heic", "webp"]
      .compactMap { UTType(filenameExtension: $0) }
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK,
          let url = panel.url,
          let image = NSImage(contentsOf: url) else { return }
    model.setDiffuseImage(image, named: url.lastPathComponent)
  }

  private func exportSelectedFormat() {
    let format = selectedExportFormat
    let panel = NSSavePanel()
    panel.nameFieldStringValue = "\(exportBaseName(for: format)).\(format.fileExtension)"
    panel.allowedContentTypes = [format.contentType]
    panel.canCreateDirectories = true
    panel.begin { response in
      guard response == .OK, let url = panel.url else { return }
      _ = writeExport(format, to: url)
    }
  }

  private func shareScene() {
    guard let url = exportURL(for: selectedExportFormat) else { return }
    shareURL = url
    isSharing = true
  }

  private func exportBaseName(for format: ExportFormat) -> String {
    let trimmed = model.fileName.trimmingCharacters(in: .whitespacesAndNewlines)
    let fallback = trimmed.isEmpty ? "SceneShape" : trimmed
    let knownExtension = ".\(format.fileExtension)"
    if fallback.lowercased().hasSuffix(knownExtension) {
      return String(fallback.dropLast(knownExtension.count))
    }
    return fallback
  }

  private func exportableScene() -> SCNScene? {
    guard let scene = model.sceneView.scene,
          let copy = scene.copy() as? SCNScene else { return nil }
    removeCamerasAndLights(from: copy.rootNode)
    return copy
  }

  private func exportURL(for format: ExportFormat) -> URL? {
    guard let scene = exportableScene() else { return nil }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("\(exportBaseName(for: format)).\(format.fileExtension)")
    guard scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) else { return nil }
    return url
  }

  private func writeExport(_ format: ExportFormat, to url: URL) -> Bool {
    guard let scene = exportableScene() else { return false }
    return scene.write(to: url, options: nil, delegate: nil, progressHandler: nil)
  }

  private func removeCamerasAndLights(from node: SCNNode) {
    for child in node.childNodes {
      if child.camera != nil || child.light != nil {
        child.removeFromParentNode()
      } else {
        removeCamerasAndLights(from: child)
      }
    }
  }
}

private struct MaterialSlotButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.caption.weight(.medium))
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .frame(maxWidth: .infinity)
      .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
      .foregroundColor(isSelected ? .white : .primary)
      .clipShape(RoundedRectangle(cornerRadius: 6))
      .opacity(configuration.isPressed ? 0.75 : 1)
  }
}

private struct SliderRow: View {
  let title: String
  @Binding var value: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.subheadline)
      Slider(value: $value)
    }
  }
}

private struct PreciseSliderRow: View {
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

struct Editor_Previews: PreviewProvider {
  static var previews: some View { Editor().environmentObject(DataModel()) }
}
