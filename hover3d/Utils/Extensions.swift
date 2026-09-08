//
//  Extensions.swift
//  quickshape
//
//  Created by BigMac on 16/07/2020.
//  Copyright © 2020 ubicolor. All rights reserved.
//

import SceneKit
import SwiftUI

extension Color {
  static var level1 = Color("level1")
  static var level2 = Color("level2")
  static var level3 = Color("level3")
  static var label = Color("reversed")
}


extension SCNMaterial {
  
  static var avColor : SCNMaterial {
    let material = SCNMaterial()
    material.name = "avColor"
    material.lightingModel = .physicallyBased
    material.metalness.contents = 0
    material.roughness.contents = 0.2
    return material
  }
  
  static var whitePlastic : SCNMaterial {
    let material = SCNMaterial()
    material.name = "whitePlastic"
    material.lightingModel = .physicallyBased
    material.metalness.contents = 0
    material.roughness.contents = 0.1
    return material
  }
  
  convenience init(hex: String) {
    self.init()
    self.name = hex
    self.lightingModel = .physicallyBased
    self.diffuse.contents = NSColor.fromHex(hex: hex)
    self.metalness.contents = 0.1
    self.roughness.contents = 0.2
    
  }
  
}

extension SCNView {
  
  var obj : URL? {
    
    let temp = FileManager.default.temporaryDirectory
    
    let url = temp.appendingPathComponent("quickShape.obj")
    
    
    if let scn = self.scene, scn.write(to: url, options: nil, delegate: nil, progressHandler: nil) {
      
      return url
      
    } else {
      
      return nil
      
    }
  }
  
  var usdz : URL? {
    
    let temp = FileManager.default.temporaryDirectory

    let url = temp.appendingPathComponent("quickShape.usdz")


    if let scn = self.scene, scn.write(to: url, options: nil, delegate: nil, progressHandler: nil) {

      return url

    } else {

      return nil

    }


  }
  
  var stl : URL? {
    
    let temp = FileManager.default.temporaryDirectory
    
    let url = temp.appendingPathComponent("quickShape.stl")
    
    let scene = SCNScene()
    
    let shape = self.scene!.rootNode.childNode(withName: "device", recursively: false)!.copy() as! SCNNode
    
    scene.rootNode.addChildNode(shape)
    
    if scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) {
      
      return url
      
    } else {
      
      return nil
      
    }
  }
  
  var dae : URL? {
    
    let temp = FileManager.default.temporaryDirectory
    
    let url = temp.appendingPathComponent("quickShape.dae")
    
    let scene = SCNScene()
    
    let shape = self.scene!.rootNode.childNode(withName: "device", recursively: false)!.copy() as! SCNNode
    
    scene.rootNode.addChildNode(shape)
    
    if scene.write(to: url, options: nil, delegate: nil, progressHandler: nil) {
      
      return url
      
    } else {
      
      return nil
      
    }
  }
  
  var scn : URL? {
    
    let temp = FileManager.default.temporaryDirectory
    
    let url = temp.appendingPathComponent("quickShape.scn")
    guard let scn = self.scene else { return nil}
    if scn.write(to: url, options: nil, delegate: nil, progressHandler: nil) {
      return url
    } else {
      return nil
    }
  }
}

extension String {
  
  func splitAtFirst(character : Character) -> [String.SubSequence] {
    return self.split(separator: character, maxSplits: 1, omittingEmptySubsequences: true)
  }
  var cgFloat : CGFloat {
    CGFloat(Double(self) ?? 0)
  }
}

extension SCNScene {
  
  convenience init(_ name: String) {
    self.init(named: "art.scnassets/\(name).scn")!
  }
}


extension NSColor {
  
  
  static func fromHex (hex:String) -> NSColor {
    var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
      cString.remove(at: cString.startIndex)
    }
    
    if ((cString.count) != 6) {
      return NSColor.gray
    }
    
    var rgbValue:UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)
    
    return NSColor(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: CGFloat(1.0)
    )
  }
}

extension SCNNode {
  
  var size : SCNVector3 {
    
    let width = boundingBox.max.x - boundingBox.min.x
    let height = boundingBox.max.y - boundingBox.min.y
    let length = boundingBox.max.z - boundingBox.min.z
    return SCNVector3(width, height, length)
  }
  
  func recenterPivot(x: CGFloat, y: CGFloat,z: CGFloat) {
    self.pivot = SCNMatrix4MakeTranslation(x, y, z)
  }

  func updateExtrusion(extrusion: CGFloat) {
    if let shape = geometry as? SCNShape {
      shape.extrusionDepth = extrusion
    }
    for node in self.childNodes {
      node.updateExtrusion(extrusion: extrusion)
    }
  }

  func updateChamfer(mode: SCNChamferMode) {
    if let shape = geometry as? SCNShape {
      shape.chamferMode = mode
    }
    for node in self.childNodes {
      node.updateChamfer(mode: mode)
    }
  }

  func updateZ(offset: CGFloat) {
    position.z = offset
    for node in self.childNodes {
      node.updateZ(offset: offset)
    }
  }


  func updateChamfer(radius: CGFloat) {
    if let shape = geometry as? SCNShape {
      shape.chamferRadius = radius
    }
    for node in self.childNodes {
      node.updateChamfer(radius: radius)
    }
  }

  func updateChamfer(profile: ChamferProfileType) {
    if let shape = geometry as? SCNShape {
      shape.chamferProfile = profile.getBezierPath()
    }
    for node in self.childNodes {
      node.updateChamfer(profile: profile)
    }
  }

  func updateMetal(ness: CGFloat) {
    if let material = geometry?.materials.first  {
      material.metalness.contents = ness
    }
    for node in self.childNodes {
      node.updateMetal(ness: ness)
    }
  }
  func updateRough(ness: CGFloat) {
    if let material = geometry?.materials.first  {
      material.roughness.contents = ness
    }
    for node in self.childNodes {
      node.updateRough(ness: ness)
    }
  }


}

extension CGFloat {
  var degreesToRadians: CGFloat { return self * .pi / 180 }
}

extension String {

  func bezier(_ offset: CGPoint = CGPoint()) -> NSBezierPath {

    let stringBits = self.split(separator: " ")
    var bitNumber = 1
    let bezierPath = NSBezierPath()
    bezierPath.flatness = 0.01

    bezierPath.windingRule = .evenOdd
    for bit in stringBits {
      if bit.description.first == "M" {
        let xAndY  = bit.description.dropFirst().split(separator: ",")
        let x = ((xAndY[0] as NSString).doubleValue).rounded()
        let y = ((xAndY[1] as NSString).doubleValue).rounded()
        //print("                 MOVE TO : ", x, y)
        bezierPath.move(to: CGPoint(x: x - Double(offset.x), y: y - Double(offset.y)))

      } else if bit.description.first == "L" {

        let xAndY  = bit.description.dropFirst().split(separator: ",")
        let x = ((xAndY[0] as NSString).doubleValue).rounded() - Double(offset.x)
        let y = ((xAndY[1] as NSString).doubleValue).rounded() - Double(offset.y)
        bezierPath.line(to: CGPoint(x: x, y: y))

      } else if bit.description.first == "C" {

        let cp1xAndY  = bit.description.dropFirst().split(separator: ",")
        let cp1x = ((cp1xAndY[0] as NSString).doubleValue).rounded() - Double(offset.x)
        let cp1y = ((cp1xAndY[1] as NSString).doubleValue).rounded() - Double(offset.y)


        let cp2xAndY  = stringBits[bitNumber].description.split(separator: ",")
        let cp2x = ((cp2xAndY[0] as NSString).doubleValue).rounded() - Double(offset.x)
        let cp2y = ((cp2xAndY[1] as NSString).doubleValue).rounded() - Double(offset.y)


        let xAndY  = stringBits[bitNumber + 1].description.split(separator: ",")
        let x = ((xAndY[0] as NSString).doubleValue).rounded() - Double(offset.x)
        let y = ((xAndY[1] as NSString).doubleValue).rounded() - Double(offset.y)

        bezierPath.curve(to: CGPoint(x: x,y: y), controlPoint1: CGPoint(x: cp1x,y: cp1y), controlPoint2: CGPoint(x: cp2x,y: cp2y))


      } else if bit.description.first == "Z" {
        bezierPath.close()
      }
      bitNumber += 1
    }

    let scale = AffineTransform(scaleByX: 1, byY: -1)
    bezierPath.transform(using: scale)

    return bezierPath

  }

  var bezierPath: (path: NSBezierPath, position: CGPoint) {

    let stringBits = self.split(separator: " ")
    var bitNumber = 1
    let bezierPath = NSBezierPath()
    bezierPath.flatness = 0.01

    bezierPath.windingRule = .evenOdd
    for bit in stringBits {
      if bit.description.first == "M" {
        let xAndY  = bit.description.dropFirst().split(separator: ",")
        let x = (xAndY[0] as NSString).doubleValue.rounded()  //<- sort this out
        let y = (xAndY[1] as NSString).doubleValue.rounded()  //<- sort this out
        //print("                 MOVE TO : ", x, y)
        bezierPath.move(to: CGPoint(x: x, y: y))

      } else if bit.description.first == "L" {

        let xAndY  = bit.description.dropFirst().split(separator: ",")
        let x = ((xAndY[0] as NSString).doubleValue).rounded()
        let y = ((xAndY[1] as NSString).doubleValue).rounded()
        bezierPath.line(to: CGPoint(x: x, y: y))

      } else if bit.description.first == "C" {

        let cp1xAndY  = bit.description.dropFirst().split(separator: ",")
        let cp1x = ((cp1xAndY[0] as NSString).doubleValue).rounded()
        let cp1y = ((cp1xAndY[1] as NSString).doubleValue).rounded()


        let cp2xAndY  = stringBits[bitNumber].description.split(separator: ",")
        let cp2x = ((cp2xAndY[0] as NSString).doubleValue).rounded()
        let cp2y = ((cp2xAndY[1] as NSString).doubleValue).rounded()


        let xAndY  = stringBits[bitNumber + 1].description.split(separator: ",")
        let x = ((xAndY[0] as NSString).doubleValue).rounded()
        let y = ((xAndY[1] as NSString).doubleValue).rounded()


        bezierPath.curve(to: CGPoint(x: x,y: y), controlPoint1: CGPoint(x: cp1x,y: cp1y), controlPoint2: CGPoint(x: cp2x,y: cp2y))


      } else if bit.description.first == "Z" {
        bezierPath.close()
      }
      bitNumber += 1
    }
    print("bounds", bezierPath.bounds)

    let bounds = bezierPath.bounds
    let center = CGPoint(x: bounds.midX, y: bounds.midY)

    let scale = AffineTransform(scaleByX: 1, byY: -1)
    bezierPath.transform(using: scale)

    let translate = AffineTransform(translationByX: -center.x, byY: center.y)
    bezierPath.transform(using: translate)

    return (bezierPath, center)

  }

}

extension SCNAction {

  static func pop(scale: CGFloat ) -> SCNAction {
    let small = SCNAction.scale(to: CGFloat(scale * 0.8) , duration: 0.05)
    let slightlyBigger = SCNAction.scale(to: CGFloat(scale * 1.1) , duration: 0.05)
    let normal = SCNAction.scale(to: CGFloat(scale), duration: 0.05)
    return SCNAction.sequence([small,slightlyBigger, normal])
  }
}


extension NSBezierPath {


  static var straight : NSBezierPath {

    let customChamfer = NSBezierPath()
    customChamfer.move(to: CGPoint(x: 0, y: 1))
    customChamfer.line(to: CGPoint(x: 1, y: 0))
    return customChamfer
  }

  static var curvedIn : NSBezierPath {
    let customChamfer = NSBezierPath()
    customChamfer.move(to: CGPoint(x: 0, y: 1))
    customChamfer.curve(to: CGPoint(x: 1, y: 0), controlPoint1: CGPoint(x: 0, y: 0), controlPoint2: CGPoint(x: 1, y: 0))
    return customChamfer
  }
  static var curvedOut : NSBezierPath {
    let customChamfer = NSBezierPath()
    customChamfer.move(to: CGPoint(x: 0, y: 1))
    customChamfer.curve(to: CGPoint(x: 1, y: 0), controlPoint1: CGPoint(x: 1, y: 1), controlPoint2: CGPoint(x: 1, y: 0))
    return customChamfer
  }

      static var tildaIn : NSBezierPath {
    let customChamfer = NSBezierPath()
    customChamfer.move(to: CGPoint(x: 0, y: 1))
    customChamfer.curve(to:  CGPoint(x: 1, y: 0),
                 controlPoint1: CGPoint(x: 0.75, y: 0.75),
                 controlPoint2: CGPoint(x: 0.25, y: 0.25))

      return customChamfer
    }


  static var tildaOut : NSBezierPath {

    let customChamfer = NSBezierPath()
    customChamfer.move(to: CGPoint(x: 0, y: 1))
    customChamfer.curve(to:  CGPoint(x: 1, y: 0),
                 controlPoint1: CGPoint(x: 0.25, y: 0.25),
                 controlPoint2: CGPoint(x: 0.75, y: 0.75))

    return customChamfer
    }

  }
