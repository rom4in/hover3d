//
//  DataModel.swift
//  hover3d
//
//  Created by BigMac on 03/12/2020.
//


import SwiftUI
import SceneKit

class DataModel : NSObject, ObservableObject {

  @Published var sceneView = SCNView()
  @Published var mamaNode = SCNNode()
  @Published var chamferRadius : CGFloat = 5
  @Published var extrusion : CGFloat = 20
  @Published var zOffset : CGFloat = 10
  @Published var currentMaterial = SCNMaterial(hex: "FFFFFF")
  @Published var currentNode = SCNNode()
  @Published var chamferMode = SCNChamferMode.front
  @Published var chamferProfile = ChamferProfileType.curvedOut

  @Published var roughness : CGFloat = 0.5
  @Published var metalness : CGFloat = 0.5

  @Published var svgSize = CGSize()

  func createNode() {
    let node = SCNNode()
    currentNode.addChildNode(node)
    currentNode = node
  }

  func upOneLevel() {
    currentNode = currentNode.parent!
  }

  func createRectNode(attributes: [String : String])  {
    guard
      let name =           attributes["id"],
      let posX =           attributes["x"],
      let posY =           attributes["y"],
      let width =          attributes["width"],
      let height =         attributes["height"]
      else { return }
    let radius =         attributes["rx"]
    var rx : CGFloat = 0
    if radius != nil {
      rx = radius!.description.cgFloat
    }

    let rectangle = NSRect(x: Double(posX)!, y: Double(posY)!, width: Double(width)!, height: Double(height)!)
    let bezier = NSBezierPath(roundedRect: rectangle, xRadius: rx, yRadius: rx)

    let offset = CGPoint(x: rectangle.midX, y: rectangle.midY)
    let translate = AffineTransform(translationByX: -offset.x, byY: -offset.y)
    bezier.transform(using: translate)

    bezier.flatness = 0.01
    let scale = AffineTransform(scaleByX: 1, byY: -1)
    bezier.transform(using: scale)

    let shape = SCNShape(path: bezier, extrusionDepth: 10)
    shape.chamferRadius = 2
    shape.chamferMode = chamferMode
    switch chamferProfile {
      case .straight: shape.chamferProfile = NSBezierPath.straight
      case .curvedIn: shape.chamferProfile = NSBezierPath.curvedIn
      case .curvedOut: shape.chamferProfile = NSBezierPath.curvedOut
      case .tildaIn: shape.chamferProfile = NSBezierPath.tildaIn
      case .tildaOut: shape.chamferProfile = NSBezierPath.tildaOut
    }


    if let hex = attributes["fill"], hex != "" {
      currentMaterial = SCNMaterial(hex: hex)
    }
    shape.materials = [currentMaterial]

    let node = SCNNode()
    node.name = name.description
    node.geometry = shape
    currentNode.addChildNode(node)
    node.position.x = offset.x - (svgSize.width / 2)
    node.position.y = (svgSize.height / 2) - offset.y


  }



  func createPathNode(attributes: [String: String]) {

    let name =  attributes["id"]
    let string = attributes["d"]
    if let bezier = string?.bezierPath {

      let shape = SCNShape(path: bezier.path, extrusionDepth: extrusion)
         shape.chamferRadius = chamferRadius
         shape.chamferMode = chamferMode


         switch chamferProfile {
           case .straight: shape.chamferProfile = NSBezierPath.straight
           case .curvedIn: shape.chamferProfile = NSBezierPath.curvedIn
           case .curvedOut: shape.chamferProfile = NSBezierPath.curvedOut
           case .tildaIn: shape.chamferProfile = NSBezierPath.tildaIn
           case .tildaOut: shape.chamferProfile = NSBezierPath.tildaOut
         }

         if let color = attributes["fill"],  color != "" {
           currentMaterial = SCNMaterial(hex: color)
         }
         shape.materials = [currentMaterial]
         let node = SCNNode()
         node.name = name?.description
         node.geometry = shape
         print("pathSize", bezier.position, svgSize)
         node.position.x = bezier.position.x - (svgSize.width / 2)
         node.position.y = (svgSize.height / 2) - bezier.position.y
         currentNode.addChildNode(node)


    }


  }

  func createPolygonNode(attributes: [String : String]) {

    print(attributes)
    guard
      let name = attributes["id"],
      let points = attributes["points"]?.components(separatedBy: " ")
      else { return  }

    print("POINTS: ", points)

    var isX = true
    var point = CGPoint()

//-----------------------------

    var cgPoints = [CGPoint]()
    var xs = [CGFloat]()
    var ys = [CGFloat]()

    for p in points {
      if isX {
        point.x = p.cgFloat
        xs.append(p.cgFloat)
      } else {
        point.y = p.cgFloat
        ys.append(p.cgFloat)
        cgPoints.append(point)
      }
      isX.toggle()
    }

    guard
      let xMin = xs.min(),
      let yMin = ys.min(),
      let xMax = xs.max(),
      let yMax = ys.max()
      else { return }

    let shapeSize = CGSize(width: xMax - xMin, height: yMax - yMin)
    let shapeOrigin = CGPoint(x: xMin, y: yMin)
    let shapeCenter = CGPoint(x: shapeOrigin.x + (shapeSize.width / 2), y: shapeOrigin.y + (shapeSize.height / 2))
    let pivotOffset = CGPoint(x: shapeOrigin.x + shapeSize.width / 2 , y: shapeOrigin.y + shapeSize.height / 2)
    let localPosition = SCNVector3(x: shapeCenter.x - (svgSize.width / 2), y:  (svgSize.height / 2) - shapeCenter.y , z: 0)

    print(svgSize, shapeSize, shapeOrigin, pivotOffset, localPosition )

    var translatedPoints = [CGPoint]()
    for point in cgPoints {
      let newPoint = CGPoint(x: point.x - pivotOffset.x, y: point.y - pivotOffset.y)
      translatedPoints.append(newPoint)
    }
    print("translatedPoints", translatedPoints)

    let bezier = NSBezierPath()
    bezier.move(to: translatedPoints[0])
    let remainingPoints = translatedPoints.dropFirst()
    for follower in remainingPoints {
      bezier.line(to: follower)
    }
    bezier.close()

    bezier.flatness = 0.01
    let scale = AffineTransform(scaleByX: 1, byY: -1)
    bezier.transform(using: scale)


    let shape = SCNShape(path: bezier, extrusionDepth: extrusion)
    shape.chamferRadius = chamferRadius
    shape.chamferMode = chamferMode
    switch chamferProfile {
      case .straight: shape.chamferProfile = NSBezierPath.straight
      case .curvedIn: shape.chamferProfile = NSBezierPath.curvedIn
      case .curvedOut: shape.chamferProfile = NSBezierPath.curvedOut
      case .tildaIn: shape.chamferProfile = NSBezierPath.tildaIn
      case .tildaOut: shape.chamferProfile = NSBezierPath.tildaOut
    }



    if let hex = attributes["fill"], hex.description != "" {
      currentMaterial = SCNMaterial(hex: hex.description)
    }

    shape.materials = [currentMaterial]
    let node = SCNNode()
    node.name = name.description
    node.geometry = shape
    currentNode.addChildNode(node)
    node.position = localPosition

  }

  func createCircleNode(attributes : [String: String]) {
    guard

      let name =     attributes["id"],
      let centerX =  attributes["cx"],
      let centerY =  attributes["cy"],
      let radius =   attributes["r"],
      let xCenter = Double(centerX),
      let yCenter = Double(centerY),
      let rx = Double(radius)

      else { return }
    let circle = NSBezierPath(ovalIn: NSRect(origin: CGPoint(x: -rx, y: -rx),
                                             size: CGSize(width: rx * 2.0, height: rx * 2.0)))
    circle.flatness = 0.01
    let scale = AffineTransform(scaleByX: 1, byY: -1)
    circle.transform(using: scale)

    let shape = SCNShape(path: circle, extrusionDepth: extrusion)
    shape.chamferRadius = chamferRadius
    shape.chamferMode = chamferMode
    switch chamferProfile {
      case .straight: shape.chamferProfile = NSBezierPath.straight
      case .curvedIn: shape.chamferProfile = NSBezierPath.curvedIn
      case .curvedOut: shape.chamferProfile = NSBezierPath.curvedOut
      case .tildaIn: shape.chamferProfile = NSBezierPath.tildaIn
      case .tildaOut: shape.chamferProfile = NSBezierPath.tildaOut
    }

    if let hex = attributes["fill"], hex != "" {
      currentMaterial = SCNMaterial(hex: hex)
    }
    shape.materials = [currentMaterial]

    let node = SCNNode()
    node.name = name.description
    node.geometry = shape
    currentNode.addChildNode(node)
    node.position.x = CGFloat(xCenter) - (svgSize.width / 2)
    node.position.y = (svgSize.height / 2) - CGFloat(yCenter)


  }

  func createEllipseNode(attributes: [String: String]) {
    print("ellipse att: ", attributes)

    guard
      let name =     attributes["id"],
      let centerX =  attributes["cx"],
      let centerY =  attributes["cy"],
      let radiusX =   attributes["rx"],
      let radiusY =   attributes["ry"],
      let xCenter = Double(centerX),
      let yCenter = Double(centerY),
      let rx = Double(radiusX),
      let ry = Double(radiusY)

      else { return }

    let circle = NSBezierPath(ovalIn: NSRect(origin: CGPoint(x: xCenter - rx, y: yCenter - ry),
                                             size: CGSize(width: rx * 2.0, height: ry * 2.0)))
    circle.flatness = 0.01
    let scale = AffineTransform(scaleByX: 1, byY: -1)
    circle.transform(using: scale)

    let shape = SCNShape(path: circle, extrusionDepth: extrusion)
    shape.chamferRadius = chamferRadius
    if let hex = attributes["fill"], hex != "" {
      currentMaterial = SCNMaterial(hex: hex)
    }
    shape.materials = [currentMaterial]

    let node = SCNNode()
    node.name = name.description
    node.geometry = shape
    shape.chamferMode = chamferMode
    shape.chamferRadius = chamferRadius
    switch chamferProfile {
      case .straight: shape.chamferProfile = NSBezierPath.straight
      case .curvedIn: shape.chamferProfile = NSBezierPath.curvedIn
      case .curvedOut: shape.chamferProfile = NSBezierPath.curvedOut
      case .tildaIn: shape.chamferProfile = NSBezierPath.tildaIn
      case .tildaOut: shape.chamferProfile = NSBezierPath.tildaOut
    }


    currentNode.addChildNode(node)
    node.position.z = 1
  }

}




