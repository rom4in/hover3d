import SwiftUI
import SceneKit

@MainActor
final class DataModel: NSObject, ObservableObject {

  struct GeometrySettings {
    var extrusion: CGFloat
    var chamferRadius: CGFloat
    var layerOffset: CGFloat
    var chamferMode: SCNChamferMode
    var chamferProfile: ChamferProfileType
  }

  static let materialNames = ["front", "back", "side", "edge"]

  struct MaterialColorPreset: Identifiable {
    let id: String
    let name: String
    let color: Color
    let metalness: CGFloat
    let roughness: CGFloat
  }

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
  @Published private(set) var selectedGeometryNodes: [SCNNode] = []
  @Published private(set) var selectedGeometrySettings: GeometrySettings?
  @Published var materialImageName: String?
  @Published var inspectorPresented = false

  private var geometrySettings: [ObjectIdentifier: GeometrySettings] = [:]
  private weak var selectionAnchorNode: SCNNode?

  @Published var svgSize = CGSize()
  @Published var fileName = "SceneShape"
  @Published var importedSVGImage: NSImage?

  let undoManager = UndoManager()
  @Published private(set) var undoState = 0

  var canUndo: Bool { undoManager.canUndo }
  var canRedo: Bool { undoManager.canRedo }

  func undo() {
    guard undoManager.canUndo else { return }
    undoManager.undo()
    undoState += 1
  }

  func redo() {
    guard undoManager.canRedo else { return }
    undoManager.redo()
    undoState += 1
  }

  func setFileName(_ value: String) {
    guard fileName != value else { return }
    let oldValue = fileName
    fileName = value
    undoManager.registerUndo(withTarget: self) { target in
      target.setFileName(oldValue)
    }
    undoManager.setActionName("Rename Scene")
    undoState += 1
  }

  var selectedMaterial: SCNMaterial? {
    guard let geometry = selectedGeometryNode?.geometry,
          geometry.materials.indices.contains(selectedMaterialIndex) else { return nil }
    return geometry.materials[selectedMaterialIndex]
  }

  private var selectedMaterials: [SCNMaterial] {
    let nodes = selectedGeometryNodes.isEmpty ? selectedGeometryNode.map { [$0] } ?? [] : selectedGeometryNodes
    return nodes.compactMap { node in
      guard let materials = node.geometry?.materials,
            materials.indices.contains(selectedMaterialIndex) else { return nil }
      return materials[selectedMaterialIndex]
    }
  }

  var geometryNodes: [SCNNode] {
    var nodes: [SCNNode] = []

    func appendGeometryNodes(from node: SCNNode) {
      if node.geometry != nil {
        nodes.append(node)
      }
      node.childNodes.forEach(appendGeometryNodes)
    }

    appendGeometryNodes(from: mamaNode)
    return nodes
  }

  var diffuseColorPresets: [MaterialColorPreset] {
    var seenColors = Set<String>()
    return geometryNodes.flatMap { node in
      node.geometry?.materials.enumerated().compactMap { index, material in
        guard let nsColor = diffuseNSColor(from: material.diffuse.contents),
            let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return nil }

        let key = [rgbColor.redComponent, rgbColor.greenComponent, rgbColor.blueComponent,
                   rgbColor.alphaComponent]
          .map { String(format: "%.4f", $0) }
          .joined(separator: ",")
        guard seenColors.insert(key).inserted else { return nil }

        let materialName = material.name ?? (Self.materialNames.indices.contains(index) ? Self.materialNames[index] : "Material")
        return MaterialColorPreset(id: key, name: materialName, color: Color(nsColor: nsColor),
                                   metalness: numericMaterialValue(material.metalness.contents),
                                   roughness: numericMaterialValue(material.roughness.contents))
      } ?? []
    }
  }

  var materialPresets: [MaterialColorPreset] {
    var seenMaterials = Set<String>()
    return geometryNodes.flatMap { node in
      node.geometry?.materials.enumerated().compactMap { index, material in
        guard let nsColor = diffuseNSColor(from: material.diffuse.contents),
              let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return nil }

        let metalness = numericMaterialValue(material.metalness.contents)
        let roughness = numericMaterialValue(material.roughness.contents)
        let colorKey = [rgbColor.redComponent, rgbColor.greenComponent, rgbColor.blueComponent,
                        rgbColor.alphaComponent]
          .map { String(format: "%.4f", $0) }
          .joined(separator: ",")
        let key = "\(colorKey),\(String(format: "%.4f", metalness)),\(String(format: "%.4f", roughness))"
        guard seenMaterials.insert(key).inserted else { return nil }

        let materialName = material.name ?? (Self.materialNames.indices.contains(index) ? Self.materialNames[index] : "Material")
        return MaterialColorPreset(id: key, name: materialName, color: Color(nsColor: nsColor),
                                   metalness: metalness, roughness: roughness)
      } ?? []
    }
  }

  private func diffuseNSColor(from contents: Any?) -> NSColor? {
    contents as? NSColor
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

  func select(node: SCNNode, material index: Int? = nil, extendingSelection: Bool = false) {
    // AppKit input callbacks can arrive during SwiftUI view updates. Enqueue
    // the entire selection transaction so its published state changes together.
    Task { @MainActor [weak self] in
      self?.applySelection(node: node, material: index, extendingSelection: extendingSelection)
    }
  }

  private func applySelection(node: SCNNode, material index: Int? = nil, extendingSelection: Bool) {
    let nodes = geometryNodes
    // An import may have replaced the scene before the queued selection runs.
    guard node.geometry != nil, nodes.contains(where: { $0 === node }) else { return }
    ensureFourMaterials(in: node)
    if extendingSelection, let anchor = selectionAnchorNode,
       let anchorIndex = nodes.firstIndex(where: { $0 === anchor }),
       let nodeIndex = nodes.firstIndex(where: { $0 === node }) {
      selectedGeometryNodes = Array(nodes[min(anchorIndex, nodeIndex)...max(anchorIndex, nodeIndex)])
    } else {
      selectedGeometryNodes = [node]
      selectionAnchorNode = node
    }
    selectedGeometryNode = node
    selectedGeometrySettings = settings(for: node)
    selectedMaterialIndex = min(max(index ?? selectedMaterialIndex, 0), Self.materialNames.count - 1)
    inspectorPresented = true
    refreshMaterialControls()
  }

  func moveSelection(by offset: Int, extendingSelection: Bool) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let nodes = geometryNodes
      guard !nodes.isEmpty else { return }
      let current = selectedGeometryNode.flatMap { node in nodes.firstIndex(where: { $0 === node }) } ?? 0
      let destination = min(max(current + offset, 0), nodes.count - 1)
      applySelection(node: nodes[destination], extendingSelection: extendingSelection)
    }
  }

  func updateSelectedExtrusion(_ value: CGFloat) {
    updateSelectedGeometry { node, settings in
      settings.extrusion = min(max(value, 0), 100)
      (node.geometry as? SCNShape)?.extrusionDepth = settings.extrusion
    }
  }

  func updateSelectedChamferRadius(_ value: CGFloat) {
    updateSelectedGeometry { node, settings in
      settings.chamferRadius = min(max(value, 0), 100)
      (node.geometry as? SCNShape)?.chamferRadius = settings.chamferRadius
    }
  }

  func updateSelectedLayerOffset(_ value: CGFloat) {
    updateSelectedGeometry { node, settings in
      settings.layerOffset = min(max(value, -100), 100)
      node.position.z = settings.layerOffset
    }
  }

  func updateSelectedChamferMode(_ mode: SCNChamferMode) {
    updateSelectedGeometry { node, settings in
      settings.chamferMode = mode
      (node.geometry as? SCNShape)?.chamferMode = mode
    }
  }

  func updateSelectedChamferProfile(_ profile: ChamferProfileType) {
    updateSelectedGeometry { node, settings in
      settings.chamferProfile = profile
      (node.geometry as? SCNShape)?.chamferProfile = profile.getBezierPath()
    }
  }

  private func settings(for node: SCNNode) -> GeometrySettings {
    let identifier = ObjectIdentifier(node)
    if let settings = geometrySettings[identifier] { return settings }

    let shape = node.geometry as? SCNShape
    let settings = GeometrySettings(
      extrusion: shape?.extrusionDepth ?? extrusion,
      chamferRadius: shape?.chamferRadius ?? chamferRadius,
      layerOffset: node.position.z,
      chamferMode: shape?.chamferMode ?? chamferMode,
      chamferProfile: chamferProfile
    )
    geometrySettings[identifier] = settings
    return settings
  }

  private func updateSelectedGeometry(
    _ update: (SCNNode, inout GeometrySettings) -> Void
  ) {
    let nodes = selectedGeometryNodes.isEmpty ? selectedGeometryNode.map { [$0] } ?? [] : selectedGeometryNodes
    let changes = nodes.compactMap { node -> (SCNNode, GeometrySettings, GeometrySettings)? in
      var settings = self.settings(for: node)
      let oldSettings = settings
      update(node, &settings)
      let changed = settings.extrusion != oldSettings.extrusion ||
        settings.chamferRadius != oldSettings.chamferRadius ||
        settings.layerOffset != oldSettings.layerOffset ||
        settings.chamferMode != oldSettings.chamferMode ||
        settings.chamferProfile != oldSettings.chamferProfile
      guard changed else { return nil }
      geometrySettings[ObjectIdentifier(node)] = settings
      return (node, oldSettings, settings)
    }
    guard !changes.isEmpty else { return }
    registerGeometryChanges(changes)
    if let selectedGeometryNode {
      selectedGeometrySettings = settings(for: selectedGeometryNode)
    }
  }

  private func registerGeometryChanges(_ changes: [(SCNNode, GeometrySettings, GeometrySettings)]) {
    undoManager.registerUndo(withTarget: self) { target in
      target.registerGeometryChanges(changes.map { ($0.0, $0.2, $0.1) })
      changes.forEach { target.applyGeometrySettings($0.1, to: $0.0) }
    }
    undoManager.setActionName("Change Geometry")
    undoState += 1
  }

  private func applyGeometrySettings(_ settings: GeometrySettings, to node: SCNNode) {
    if let shape = node.geometry as? SCNShape {
      shape.extrusionDepth = settings.extrusion
      shape.chamferRadius = settings.chamferRadius
      shape.chamferMode = settings.chamferMode
      shape.chamferProfile = settings.chamferProfile.getBezierPath()
    }
    node.position.z = settings.layerOffset
    geometrySettings[ObjectIdentifier(node)] = settings
    if selectedGeometryNode === node {
      selectedGeometrySettings = settings
      refreshMaterialControls()
    }
  }

  func selectMaterial(_ index: Int) {
    guard Self.materialNames.indices.contains(index) else { return }
    selectedMaterialIndex = index
    inspectorPresented = true
    refreshMaterialControls()
  }

  func setDiffuseColor(_ color: Color) {
    let materials = selectedMaterials
    guard !materials.isEmpty else { return }
    let newContents = NSColor(color)
    let changes = materials.map { material in
      (material, material.diffuse.contents, materialImageName, newContents as Any?, nil as String?)
    }
    diffuseColor = color
    materials.forEach { $0.diffuse.contents = newContents }
    materialImageName = nil
    registerMaterialChanges(changes)
  }

  func setMaterialPreset(_ preset: MaterialColorPreset) {
    let materials = selectedMaterials
    guard !materials.isEmpty else { return }

    let newDiffuse = NSColor(preset.color)
    let changes = materials.map { material in
      MaterialPresetChange(
        material: material,
        oldDiffuse: material.diffuse.contents,
        oldImageName: materialImageName,
        oldMetalness: numericMaterialValue(material.metalness.contents),
        oldRoughness: numericMaterialValue(material.roughness.contents),
        newDiffuse: newDiffuse,
        newImageName: nil,
        newMetalness: preset.metalness,
        newRoughness: preset.roughness
      )
    }

    materials.forEach {
      $0.diffuse.contents = newDiffuse
      $0.metalness.contents = preset.metalness
      $0.roughness.contents = preset.roughness
    }
    diffuseColor = preset.color
    metalness = preset.metalness
    roughness = preset.roughness
    materialImageName = nil
    registerMaterialPresetChanges(changes)
  }

  func setDiffuseImage(_ image: NSImage, named name: String) {
    let materials = selectedMaterials
    guard !materials.isEmpty else { return }
    let changes = materials.map { material in
      (material, material.diffuse.contents, materialImageName, image as Any?, name as String?)
    }
    materials.forEach { $0.diffuse.contents = image }
    materialImageName = name
    registerMaterialChanges(changes)
  }

  func clearDiffuseImage() {
    let materials = selectedMaterials
    guard !materials.isEmpty else { return }
    let newContents = NSColor(diffuseColor)
    let changes = materials.map { material in
      (material, material.diffuse.contents, materialImageName, newContents as Any?, nil as String?)
    }
    materials.forEach { $0.diffuse.contents = newContents }
    materialImageName = nil
    registerMaterialChanges(changes)
  }

  func updateSelectedMetalness(_ value: CGFloat) {
    let clamped = min(max(value, 0), 1)
    let materials = selectedMaterials
    guard !materials.isEmpty,
          metalness != clamped || materials.contains(where: { numericMaterialValue($0.metalness.contents) != clamped }) else { return }
    let changes = materials.map { ($0, numericMaterialValue($0.metalness.contents), clamped) }
    metalness = clamped
    materials.forEach { $0.metalness.contents = clamped }
    registerNumericMaterialChanges(changes, keyPath: "metalness")
  }

  func updateSelectedRoughness(_ value: CGFloat) {
    let clamped = min(max(value, 0), 1)
    let materials = selectedMaterials
    guard !materials.isEmpty,
          roughness != clamped || materials.contains(where: { numericMaterialValue($0.roughness.contents) != clamped }) else { return }
    let changes = materials.map { ($0, numericMaterialValue($0.roughness.contents), clamped) }
    roughness = clamped
    materials.forEach { $0.roughness.contents = clamped }
    registerNumericMaterialChanges(changes, keyPath: "roughness")
  }

  private func registerMaterialChanges(_ changes: [(SCNMaterial, Any?, String?, Any?, String?)]) {
    undoManager.registerUndo(withTarget: self) { target in
      target.registerMaterialChanges(changes.map { ($0.0, $0.3, $0.4, $0.1, $0.2) })
      changes.forEach { $0.0.diffuse.contents = $0.1 }
      target.materialImageName = changes.first?.2
      target.refreshMaterialControls()
    }
    undoManager.setActionName("Change Material")
    undoState += 1
  }

  private struct MaterialPresetChange {
    let material: SCNMaterial
    let oldDiffuse: Any?
    let oldImageName: String?
    let oldMetalness: CGFloat
    let oldRoughness: CGFloat
    let newDiffuse: Any?
    let newImageName: String?
    let newMetalness: CGFloat
    let newRoughness: CGFloat
  }

  private func registerMaterialPresetChanges(_ changes: [MaterialPresetChange]) {
    undoManager.registerUndo(withTarget: self) { target in
      target.registerMaterialPresetChanges(changes.map {
        MaterialPresetChange(
          material: $0.material,
          oldDiffuse: $0.newDiffuse,
          oldImageName: $0.newImageName,
          oldMetalness: $0.newMetalness,
          oldRoughness: $0.newRoughness,
          newDiffuse: $0.oldDiffuse,
          newImageName: $0.oldImageName,
          newMetalness: $0.oldMetalness,
          newRoughness: $0.oldRoughness
        )
      })
      changes.forEach {
        $0.material.diffuse.contents = $0.oldDiffuse
        $0.material.metalness.contents = $0.oldMetalness
        $0.material.roughness.contents = $0.oldRoughness
      }
      target.materialImageName = changes.first?.oldImageName
      target.refreshMaterialControls()
    }
    undoManager.setActionName("Apply Material Preset")
    undoState += 1
  }

  private func registerNumericMaterialChanges(_ changes: [(SCNMaterial, CGFloat, CGFloat)], keyPath: String) {
    undoManager.registerUndo(withTarget: self) { target in
      target.registerNumericMaterialChanges(changes.map { ($0.0, $0.2, $0.1) }, keyPath: keyPath)
      changes.forEach { change in
        if keyPath == "metalness" { change.0.metalness.contents = change.1 }
        else { change.0.roughness.contents = change.1 }
      }
      target.refreshMaterialControls()
    }
    undoManager.setActionName("Change Material")
    undoState += 1
  }

  private func numericMaterialValue(_ value: Any?) -> CGFloat {
    value as? CGFloat ?? (value as? NSNumber).map(CGFloat.init(truncating:)) ?? 0
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
    selectedGeometryNode = nil
    selectedGeometryNodes = []
    selectionAnchorNode = nil
    selectedGeometrySettings = nil
    geometrySettings.removeAll()
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
    node.position.z = 0
  }

}
