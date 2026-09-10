//
//  SVGParser.swift
//  quickshape
//
//  Created by BigMac on 03/08/2020.
//  Copyright © 2020 ubicolor. All rights reserved.
//

import SwiftUI
import SceneKit

// XMLParser invokes its delegate synchronously from importSVG on the main actor.
extension DataModel: @preconcurrency XMLParserDelegate {

  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

    print(attributeDict)

    switch elementName {
      case "svg" :
        mamaNode = SCNNode()
        mamaNode.castsShadow = true
        mamaNode.name = "mamanode"
        currentNode = mamaNode

      if let viewBox = attributeDict["viewBox"] {
        let values = svgNumbers(in: viewBox)
        if values.count == 4 {
          svgSize = CGSize(width: values[2], height: values[3])
        }
      } else if let height = attributeDict["height"], let width = attributeDict["width"] {
        svgSize = CGSize(width: svgNumbers(in: width).first ?? 0,
                         height: svgNumbers(in: height).first ?? 0)
      }

    case "g":

      let childNode = SCNNode()
      if let id = attributeDict["id"] {
        childNode.name = id.description
      }

      if let transform = attributeDict["transform"] {
        applySVGTransform(transform, to: childNode)
      }

      if let color = attributeDict["fill"] {
        if color.description != "" {
          print("HEX", color)
          currentMaterial = SCNMaterial(hex: color)
        }
      }

      currentNode.addChildNode(childNode)
      currentNode = childNode
      // SVG groups are a 2D organisational hierarchy. Applying the layer
      // offset to every nested group compounds Z depth in complex artwork.
      // Geometry owns its extrusion depth; groups must remain at Z = 0.

    case "path":
      createSVGPathNode(attributes: attributeDict)
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

private extension DataModel {
  func svgNumbers(in string: String) -> [CGFloat] {
    let pattern = #"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?"#
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
    let range = NSRange(string.startIndex..., in: string)
    return expression.matches(in: string, range: range).compactMap {
      Range($0.range, in: string).flatMap { CGFloat(Double(string[$0]) ?? 0) }
    }
  }

  func applySVGTransform(_ transform: String, to node: SCNNode) {
    let pattern = #"([A-Za-z]+)\s*\(([^)]*)\)"#
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return }
    let range = NSRange(transform.startIndex..., in: transform)
    for match in expression.matches(in: transform, range: range) {
      guard let nameRange = Range(match.range(at: 1), in: transform),
            let valuesRange = Range(match.range(at: 2), in: transform) else { continue }
      let values = svgNumbers(in: String(transform[valuesRange]))
      switch transform[nameRange].lowercased() {
      case "translate":
        guard let x = values.first else { continue }
        node.position.x += x
        node.position.y -= values.dropFirst().first ?? 0
      case "scale":
        guard let x = values.first else { continue }
        let y = values.dropFirst().first ?? x
        node.scale.x *= x
        node.scale.y *= y
      case "rotate":
        if let degrees = values.first { node.eulerAngles.z -= degrees.degreesToRadians }
      case "matrix":
        guard values.count == 6 else { continue }
        node.scale.x *= values[0]
        node.scale.y *= values[3]
        node.position.x += values[4]
        node.position.y -= values[5]
      default:
        print("Ignoring unsupported SVG transform: \(transform[nameRange])")
      }
    }
  }
}
