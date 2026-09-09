//
//  hover3dApp.swift
//  hover3d
//
//  Created by BigMac on 03/12/2020.
//

import SwiftUI

@main
struct hover3dApp: App {

  @StateObject private var model = DataModel()

    var body: some Scene {
        WindowGroup {
          ContentView()
            .environmentObject(model)
            .frame(minWidth: 800, minHeight: 500)
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
          CommandGroup(replacing: .undoRedo) {
            Button("Undo") { model.undo() }
              .keyboardShortcut("z", modifiers: .command)
              .disabled(!model.canUndo)
            Button("Redo") { model.redo() }
              .keyboardShortcut("z", modifiers: [.command, .shift])
              .disabled(!model.canRedo)
          }
        }
    }
}
