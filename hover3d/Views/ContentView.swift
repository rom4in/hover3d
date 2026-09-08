//
//  ContentView.swift
//  hover3d
//
//  Created by BigMac on 03/12/2020.
//

import SwiftUI

struct ContentView: View {

  @EnvironmentObject var model : DataModel
  @State var isDropping = false

    var body: some View {

      HStack(spacing: 0) {

        Editor()
          .frame(minWidth: 300, idealWidth: 300, maxWidth: 300, maxHeight: .infinity)
          .background(Color(NSColor.windowBackgroundColor))

        Divider()

        HoverView(sceneView: $model.sceneView)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
          .onDrop(of: ["public.file-url"], isTargeted: $isDropping) { providers -> Bool in
            providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
              if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {

                DispatchQueue.main.async {
                  do {
                    let data = try Data(contentsOf: url)
                    let parser = XMLParser(data: data)
                    parser.delegate = self.model
                    parser.parse()
                  } catch {
                    print("data error")
                  }
                }
              }
            })
            return true
        }
          .toolbar {
            HStack {

              Divider()

              Button(action : {

                //model.exportRender()

              }) {

                Image(systemName: "square.and.arrow.up")}


  //            Button(action: {
  //              withAnimation {
  //              showAnimation.toggle()
  //              }
  //            }) {
  //              Image(systemName: "speedometer")
  //            }
            }.environmentObject(model)
          }

      }
      .onAppear {
        let scene = SCNScene("cube")
        self.model.sceneView.scene = scene
        scene.background.contents = nil //NSColor(white: 0.3, alpha: 1)
        self.model.mamaNode = scene.rootNode.childNodes.first!
        self.model.currentNode = self.model.mamaNode

        for screen in NSScreen.screens {
          print("screen", screen.deviceDescription)
        }
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



import SwiftUI
import SceneKit

struct HoverView : NSViewRepresentable {

  @Binding var sceneView : SCNView

  func makeNSView(context: Context) -> SCNView {

    sceneView.allowsCameraControl = true
    sceneView.autoenablesDefaultLighting = true
    sceneView.isJitteringEnabled = true
    sceneView.defaultCameraController.inertiaFriction = 0.18
    sceneView.antialiasingMode = .multisampling16X
    sceneView.backgroundColor = .windowBackgroundColor

    return sceneView
  }
  func updateNSView(_ view: SCNView, context: Context) {
  }

}
