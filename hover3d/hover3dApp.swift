//
//  hover3dApp.swift
//  hover3d
//
//  Created by BigMac on 03/12/2020.
//

import SwiftUI

@main
struct hover3dApp: App {

  let model = DataModel()

    var body: some Scene {
        WindowGroup {
          ContentView()
            .environmentObject(model)
            .frame(minWidth: 800, minHeight: 500)
        }.windowToolbarStyle(UnifiedWindowToolbarStyle())
    }
}
//
//enum  Selection {
//  case scene, export
//}
