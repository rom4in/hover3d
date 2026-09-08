//
//  SegmentedControl.swift
//  quickshape
//
//  Created by BigMac on 05/08/2020.
//  Copyright © 2020 ubicolor. All rights reserved.
//

import SwiftUI
import SceneKit



struct ChamferModeSelector: View {

  var node : SCNNode
  @Binding var mode : SCNChamferMode

  var body: some View {

    VStack(spacing: 20) {

      Button(action: {
        self.mode = .both
        self.node.updateChamfer(mode: self.mode)
      }) {
        ZStack {
          Color.clear
          Text("both")
        }
      }

      HStack(spacing: 20) {
        Button(action: {
          self.mode = .front
          self.node.updateChamfer(mode: self.mode)

        }) {
          ZStack {
          Color.clear
          Text("front")
          }
        }

        Button(action: {
          self.mode = .back
          self.node.updateChamfer(mode: self.mode)

        }) {
          ZStack {
          Color.clear
          Text("back")
          }
        }
      }
    }
  }
}

enum ChamferProfileType  {
  case straight
  case curvedIn
  case curvedOut
  case tildaIn
  case tildaOut

  func getBezierPath() -> NSBezierPath {
    switch self {
      case .straight: return NSBezierPath.straight
      case .curvedIn: return NSBezierPath.curvedIn
      case .curvedOut: return NSBezierPath.curvedOut
      case .tildaIn: return NSBezierPath.tildaIn
      case .tildaOut: return NSBezierPath.tildaOut
    }
  }
}


struct ChamferProfileSelector: View {

  var node : SCNNode
  //@Binding var profile : NSBezierPath
  @Binding var profile : ChamferProfileType

  var body: some View {

      VStack(spacing: 20) {

        Button(action: {
          self.profile = .straight
          self.node.updateChamfer(profile: self.profile)
        }) {
          ZStack {
          Color.clear
          Text("straight")
          }
        }

        HStack(spacing: 20) {

          Button(action: {
            self.profile = .curvedOut
            self.node.updateChamfer(profile: self.profile)
          }) {
            ZStack {
            Color.clear
            Text("curveOut")
            }
          }

          Button(action: {
            self.profile = .curvedIn
            self.node.updateChamfer(profile: self.profile)
          }) {
            ZStack {
            Color.clear
            Text("curveIn")
            }
          }
        }


        HStack(spacing: 20) {
          Button(action: {
            self.profile = .tildaIn
            self.node.updateChamfer(profile: self.profile)
          }) {
            ZStack {
            Color.clear
            Text("TildaIn")
            }
          }

          Button(action: {
            self.profile = .tildaOut
            self.node.updateChamfer(profile: self.profile)
          }) {
            ZStack {
            Color.clear
            Text("TildaOut")
            }
          }
        }

        Color.clear

    }

  }
}
