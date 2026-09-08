//
//  SVGParser.swift
//  quickshape
//
//  Created by BigMac on 03/08/2020.
//  Copyright © 2020 ubicolor. All rights reserved.
//

import SwiftUI
import SceneKit

extension DataModel : XMLParserDelegate {

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

    print(attributeDict)

    switch elementName {
      case "svg" :
        mamaNode = SCNNode()
        mamaNode.castsShadow = true
        mamaNode.name = "mamanode"
        currentNode = mamaNode

      guard let height = attributeDict["height"], let width = attributeDict["width"] else { return }

        svgSize.width = width.dropLast(2).description.cgFloat
        svgSize.height = height.dropLast(2).description.cgFloat

    case "g":

      let childNode = SCNNode()
      if let id = attributeDict["id"] {
        childNode.name = id.description
      }

    if let transform = attributeDict["transform"] {
      //print("transform : ",transform)
      let instructions = transform.components(separatedBy: ") ")
      print("instructions: ", instructions)

      for instruction in instructions {
        if instruction.prefix(10) == "translate(" {
          let translation = instruction.dropFirst(10).description.components(separatedBy: ", ")
          childNode.position.x += translation[0].cgFloat
          let y = translation[1].replacingOccurrences(of: ")", with: "")
          childNode.position.y -= y.cgFloat
          print("translated x", translation[0].cgFloat, "y: ", y)
        }
        if instruction.prefix(7) == "rotate(" {
          let rotationAngle = instruction.dropFirst(7).description
          childNode.eulerAngles.z = -rotationAngle.cgFloat.degreesToRadians
        }
      }
      }

      if let color = attributeDict["fill"] {
        if color.description != "" {
          print("HEX", color)
          currentMaterial = SCNMaterial(hex: color)
        }
      }

      currentNode.addChildNode(childNode)
      currentNode = childNode
      currentNode.position.z = zOffset

    case "path": createPathNode(attributes: attributeDict)
    case "circle": createCircleNode(attributes: attributeDict)
    case "ellipse": createEllipseNode(attributes: attributeDict)
    case "rect": createRectNode(attributes: attributeDict)
    case "polygon": createPolygonNode(attributes: attributeDict)
    case "title": break
    default: print("AMAZING Discovery NEW ELEMENT! 🥳🥳🥳", elementName)
    }
  }
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

    switch elementName {

    case "g": upOneLevel()

    case "svg":
      currentNode = mamaNode

      // Keep the camera and lighting that are supplied by the base scene.  The
      // imported geometry can be written to disk without a camera, but there is
      // then nothing left for SCNView to render after an import.
      for node in sceneView.scene!.rootNode.childNodes {
        if node.name == "mamanode" {
          node.removeFromParentNode()
        }
      }
      sceneView.scene?.rootNode.addChildNode(mamaNode)

    default: print("endOf \(elementName)")
    }
  }

}
