//
//  Editor.swift
//  hover3d
//

import SwiftUI
import SceneKit

struct Editor: View {
  @EnvironmentObject var model: DataModel
  @State private var isSharing = false
  @State private var fileName = "SceneShape"

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
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

        GroupBox(label: Text("Material")) {
          VStack(alignment: .leading, spacing: 12) {
            SliderRow(title: "Metalness", value: Binding(
              get: { model.metalness },
              set: { value in
                model.metalness = value
                model.mamaNode.updateMetal(ness: value)
              }
            ))
            SliderRow(title: "Roughness", value: Binding(
              get: { model.roughness },
              set: { value in
                model.roughness = value
                model.mamaNode.updateRough(ness: value)
              }
            ))
          }.padding(.top, 4)
        }

        Divider()
        Button(action: openSVGFile) {
          Label("Import SVG", systemImage: "square.and.arrow.down")
            .frame(maxWidth: .infinity)
        }.buttonStyle(.bordered)

        GroupBox(label: Text("Export")) {
          VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
              TextField("Scene name", text: $fileName).textFieldStyle(.roundedBorder)
              Text(".scn").foregroundColor(.secondary)
            }
            HStack {
              Button(action: exportScn) {
                Label("Save scene", systemImage: "square.and.arrow.up")
              }
              Button(action: { isSharing = true }) {
                Label("Share", systemImage: "square.and.arrow.up.on.square")
              }
            }.buttonStyle(.bordered)
          }.padding(.top, 4)
        }
      }.padding(16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(
      ShareMenu(isPresented: $isSharing, sharingItems: [model.sceneView.scn as Any])
        .allowsHitTesting(isSharing)
    )
  }

  func exportScn() {
    let panel = NSSavePanel()
    panel.nameFieldStringValue = "\(fileName).scn"
    panel.canCreateDirectories = true
    panel.begin { response in
      guard response == .OK, let url = panel.url, let scene = model.sceneView.scene else { return }
      _ = scene.write(to: url, options: nil, delegate: nil, progressHandler: nil)
    }
  }

  func openSVGFile() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedFileTypes = ["public.svg-image"]
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    fileName = url.deletingPathExtension().lastPathComponent
    let xmlParser = XMLParser(contentsOf: url)
    xmlParser?.delegate = model
    xmlParser?.parse()
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

struct Editor_Previews: PreviewProvider {
  static var previews: some View { Editor().environmentObject(DataModel()) }
}
