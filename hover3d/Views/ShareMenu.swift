//
//  ShareMenu.swift
//  quickshape
//
//  Created by BigMac on 04/08/2020.
//  Copyright © 2020 ubicolor. All rights reserved.
//

import SwiftUI

struct ShareMenu: NSViewRepresentable {
    @Binding var isPresented: Bool
    var sharingItems: [Any]

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            let picker = NSSharingServicePicker(items: sharingItems)
            picker.delegate = context.coordinator

            Task { @MainActor in
                picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(owner: self)
    }

    // AppKit delivers picker callbacks on the main thread.
    @MainActor
    final class Coordinator: NSObject, @preconcurrency NSSharingServicePickerDelegate {
        let owner: ShareMenu

        init(owner: ShareMenu) {
            self.owner = owner
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {

            // do here whatever more needed here with selected service

            sharingServicePicker.delegate = nil   // << cleanup
            self.owner.isPresented = false        // << dismiss
        }
    }
}

#Preview {
    ShareMenu(isPresented: .constant(false), sharingItems: [])
}
