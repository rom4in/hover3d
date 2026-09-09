import SwiftUI
import SceneKit

struct ContentView: View {

  @EnvironmentObject var model : DataModel

    var body: some View {

      NavigationSplitView {
        Editor()
          .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 380)
      } detail: {
        HStack(spacing: 0) {
          HoverView(sceneView: $model.sceneView, model: model)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

          Divider()

          MaterialPanel()
            .frame(width: model.materialPanelExpanded ? 300 : 56)
            .frame(maxHeight: .infinity)
        }
      }
      .navigationSplitViewStyle(.balanced)
      .onAppear {
        let scene = SCNScene("cube")
        self.model.sceneView.scene = scene
        scene.background.contents = nil //NSColor(white: 0.3, alpha: 1)
        self.model.mamaNode = scene.rootNode.childNodes.first!
        self.model.currentNode = self.model.mamaNode
        self.model.ensureFourMaterials(in: self.model.mamaNode)

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



