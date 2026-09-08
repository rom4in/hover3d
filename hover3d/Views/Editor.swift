//
//  Editor.swift
//  quickshape
//
//  Created by BigMac on 04/08/2020.
//  Copyright © 2020 ubicolor. All rights reserved.
//

import SwiftUI
import SceneKit

struct Editor: View {

  @EnvironmentObject var model : DataModel
  @State private var isSharing = false
  @State private var fileName = "SceneShape"
  @State private var exportType = ExportFileType.scn

  enum ExportFileType : String {
    case scn, obj, usdz, dae
  }

  var body: some View {

      ScrollView {
      VStack {
        VStack(spacing: 20) {

          Slider(value: Binding(get: { self.model.extrusion / 100 }, set: { newValue in
            self.model.extrusion = newValue * 100
            for node in self.model.mamaNode.childNodes {
              node.updateExtrusion(extrusion: self.model.extrusion)
            }

          }
            )
          )

          Slider(value : Binding(get: { self.model.zOffset / 100 }, set: { newValue in
            withAnimation {
              self.model.zOffset = newValue * 100
              self.model.mamaNode.childNodes.first?.updateZ(offset: self.model.zOffset)
            }
          }))
        }


        VStack(spacing: 20) {


          Text("Chamfer").bold()
          Text("Mode")

          ChamferModeSelector(node: model.mamaNode, mode: $model.chamferMode)

          Text("Profile")
          ChamferProfileSelector(node: model.mamaNode, profile: $model.chamferProfile)

          Text("Raduis")
          Slider(value: Binding(get: { self.model.chamferRadius / 16 }, set: { newValue in
            self.model.chamferRadius = newValue * 16
            for node in self.model.mamaNode.childNodes {
              node.updateChamfer(radius: self.model.chamferRadius)
            }
          }))


        }


        VStack {
          VStack {
            Text("Material").bold()


            Slider(value: Binding(get: { self.model.metalness }, set: { newValue in
            self.model.metalness = newValue
              for node in self.model.mamaNode.childNodes {
                node.updateMetal(ness: self.model.metalness)
              }
          }))

            Slider(value: Binding( get: { self.model.roughness }, set: { newValue in
            self.model.roughness = newValue
              for node in self.model.mamaNode.childNodes {
                node.updateRough(ness: self.model.roughness)
              }
          }))
          }
        }



      }//.padding()
      VStack {
      HStack {
        Text("Import")
        Button(action: {
          self.openSVGFile()
        }) {
          Text("􀈄").padding(.horizontal, 4)
        }
      }


      VStack  {
      VStack {
        HStack {
        TextField("SceneShape", text: $fileName).textFieldStyle(RoundedBorderTextFieldStyle())
        Text(".scn").font(.subheadline)
          }
        HStack {

                    Button(action: {

                      self.exportScn()

                    }) {
                      Image("save")
                    }

                    Button(action: {
                      self.isSharing = true
                    }) {
                      Image("airplay")
                    }
                  }

      }

        .padding()
        .frame(height: 120)
        .overlay(ShareMenu(isPresented: self.$isSharing, sharingItems: [self.model.sceneView.scn as Any])
                  .allowsHitTesting(isSharing)
                  .padding(.bottom)
                  .frame(alignment: .bottomTrailing)
      )
    }

      }
      }.padding(.horizontal)
  }

  func exportScn() {

    let panel = NSSavePanel()
    panel.nameFieldStringValue = "\(fileName).scn"
    panel.canCreateDirectories = true
    panel.begin { (response) in

      let scn = self.model.sceneView.scene
      
      if let url = panel.url, let exportScene = scn,  exportScene.write(to: url, options: nil, delegate: nil, progressHandler: nil) {

        print("yoooo!")
      } else {
        print("boooo!")
      }
    }

  }

  func openSVGFile() {

    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowedFileTypes = ["public.svg-image"]
    panel.allowsMultipleSelection = false
    if (panel.runModal() ==  NSApplication.ModalResponse.OK) {
      let result = panel.url

      if let url = result {
        let path: String = url.path
        print(url)
        print(path)
        fileName = url.lastPathComponent.dropLast(4).description
        let xmlParser = XMLParser(contentsOf: url)
        xmlParser?.delegate = model
        xmlParser?.parse()
      }
    }
  }

}

struct Editor_Previews: PreviewProvider {
  static var previews: some View {
    Editor().environmentObject(DataModel())
  }
}
