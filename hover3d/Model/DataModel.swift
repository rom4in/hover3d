//
//  DataModel.swift
//  hover3d
//
//  Created by BigMac on 03/12/2020.
//


import SwiftUI
import SceneKit

class DataModel : NSObject, ObservableObject {

  static let materialNames = ["front", "back", "side", "edge"]

  @Published var sceneView = SCNView()
  @Published var mamaNode = SCNNode()
  @Published var chamferRadius : CGFloat = 5
  @Published var extrusion : CGFloat = 20
  @Published var zOffset : CGFloat = 0
  @Published var currentMaterial = SCNMaterial(hex: "FFFFFF")
  @Published var currentNode = SCNNode()
  @Published var chamferMode = SCNChamferMode.front
  @Published var chamferProfile = ChamferProfileType.curvedOut

  @Published var roughness : CGFloat = 0.5
  @Published var metalness : CGFloat = 0.5
  @Published var diffuseColor = Color.white
  @Published var selectedMaterialIndex = 0
  @Published var selectedGeometryNode: SCNNode?
  @Published var materialImageName: String?
  @Published var materialPanelExpanded = false

  @Published var svgSize = CGSize()
  @Published var fileName = "SceneShape"
  @Published var importedSVGImage: NSImage?

  var selectedMaterial: SCNMaterial? {
    guard let geometry = selectedGeometryNode?.geometry,
          geometry.materials.indices.contains(selectedMaterialIndex) else { return nil }
    return geometry.materials[selectedMaterialIndex]
  }

  func materials(from source: SCNMaterial) -> [SCNMaterial] {
    Self.materialNames.map { name in
      let material = (source.copy() as? SCNMaterial) ?? SCNMaterial()
      material.name = name
      material.lightingModel = .physicallyBased
      return material
    }
  }

  func ensureFourMaterials(in node: SCNNode) {
    if let geometry = node.geometry,
       geometry.materials.count != Self.materialNames.count ||
       zip(geometry.materials, Self.materialNames).contains(where: { $0.name != $1 }) {
      geometry.materials = materials(from: geometry.materials.first ?? currentMaterial)
    }
    node.childNodes.forEach(ensureFourMaterials)
  }

  func select(node: SCNNode, material index: Int? = nil) {
    guard node.geometry != nil else { return }
    ensureFourMaterials(in: node)
    selectedGeometryNode = node
    selectedMaterialIndex = min(max(index ?? selectedMaterialIndex, 0), Self.materialNames.count - 1)
    materialPanelExpanded = true
    refreshMaterialControls()
  }

  func selectMaterial(_ index: Int) {
    guard Self.materialNames.indices.contains(index) else { return }
    selectedMaterialIndex = index
    materialPanelExpanded = true
    refreshMaterialControls()
  }

  func setDiffuseColor(_ color: Color) {
    diffuseColor = color
    selectedMaterial?.diffuse.contents = NSColor(color)
    materialImageName = nil
  }

  func setDiffuseImage(_ image: NSImage, named name: String) {
    selectedMaterial?.diffuse.contents = image
    materialImageName = name
  }

  func clearDiffuseImage() {
    selectedMaterial?.diffuse.contents = NSColor(diffuseColor)
    materialImageName = nil
  }

  func updateSelectedMetalness(_ value: CGFloat) {
    let clamped = min(max(value, 0), 1)
    metalness = clamped
    selectedMaterial?.metalness.contents = clamped
  }

  func updateSelectedRoughness(_ value: CGFloat) {
    let clamped = min(max(value, 0), 1)
    roughness = clamped
    selectedMaterial?.roughness.contents = clamped
  }

  private func refreshMaterialControls() {
    guard let material = selectedMaterial else { return }
    if let color = material.diffuse.contents as? NSColor {
      diffuseColor = Color(color)
      materialImageName = nil
    } else if material.diffuse.contents is NSImage {
      materialImageName = "Image"
    }
    metalness = material.metalness.contents as? CGFloat
      ?? (material.metalness.contents as? NSNumber).map(CGFloat.init(truncating:))
      ?? 0
    roughness = material.roughness.contents as? CGFloat
      ?? (material.roughness.contents as? NSNumber).map(CGFloat.init(truncating:))
      ?? 0
  }

  func importSVG(from url: URL) {
    fileName = url.deletingPathExtension().lastPathComponent
    importedSVGImage = NSImage(contentsOf: url)
    zOffset = 0
    mamaNode.updateZ(offset: 0)
    guard let data = try? Data(contentsOf: url) else { return }
    let parser = XMLParser(data: data)
    parser.delegate = self
    parser.parse()
  }

  func createNode() {
    let node = SCNNode()
    currentNode.addChildNode(node)
    currentNode = node
  }

  func upOneLevel() {
    if let parent = currentNode.parent {
      currentNode = parent
    }
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
    shape.materials = materials(from: currentMaterial)

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
         shape.materials = materials(from: currentMaterial)
         let node = SCNNode()
         node.name = name?.description
         node.geometry = shape
         print("pathSize", bezier.position, svgSize)
         node.position.x = bezier.position.x - (svgSize.width / 2)
         node.position.y = (svgSize.height / 2) - bezier.position.y
         currentNode.addChildNode(node)


    }


  }

  /// Tolerant SVG path import for modern SVG files. It supports absolute and
  /// relative move, line, horizontal, vertical, cubic-curve and arc commands.
  /// Arc segments are drawn as curves, preserving a visible filled silhouette.
  func createSVGPathNode(attributes: [String: String]) {
    guard let source = attributes["d"], let path = source.svgBezierPath else { return }
    guard attributes["fill"] != "none" else { return }

    let bounds = path.bounds
    guard !bounds.isEmpty else { return }
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    path.transform(using: AffineTransform(translationByX: -center.x, byY: -center.y))
    path.transform(using: AffineTransform(scaleByX: 1, byY: -1))

    let shape = SCNShape(path: path, extrusionDepth: extrusion)
    shape.chamferRadius = chamferRadius
    shape.chamferMode = chamferMode
    shape.chamferProfile = chamferProfile.getBezierPath()
    if let fill = attributes["fill"], fill != "none" { currentMaterial = SCNMaterial(hex: fill) }
    shape.materials = materials(from: currentMaterial)

    let node = SCNNode(geometry: shape)
    node.name = attributes["id"]
    node.position = SCNVector3(center.x - svgSize.width / 2, svgSize.height / 2 - center.y, 0)
    if let transform = attributes["transform"] { applyPathTransform(transform, to: node) }
    currentNode.addChildNode(node)
  }

  private func applyPathTransform(_ transform: String, to node: SCNNode) {
    let values = transform.svgNumberValues
    if transform.contains("matrix"), values.count == 6 {
      let sourceX = node.position.x + svgSize.width / 2
      let sourceY = svgSize.height / 2 - node.position.y
      node.scale.x *= values[0]
      node.scale.y *= values[3]
      node.position.x = sourceX * values[0] + values[4] - svgSize.width / 2
      node.position.y = svgSize.height / 2 - (sourceY * values[3] + values[5])
    } else if transform.contains("translate"), let x = values.first {
      node.position.x += x
      node.position.y -= values.dropFirst().first ?? 0
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

    shape.materials = materials(from: currentMaterial)
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
    shape.materials = materials(from: currentMaterial)

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
    shape.materials = materials(from: currentMaterial)

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
