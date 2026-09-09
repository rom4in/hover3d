import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
  case scn
  case usdz
  case usd
  case dae
  case obj
  case stl
  case ply
  case abc

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .scn: return "SceneKit"
    case .usdz: return "USDZ"
    case .usd: return "USD"
    case .dae: return "Collada"
    case .obj: return "OBJ"
    case .stl: return "STL"
    case .ply: return "PLY"
    case .abc: return "Alembic"
    }
  }

  var fileExtension: String { rawValue }

  var contentType: UTType {
    UTType(filenameExtension: fileExtension) ?? .data
  }

  var summary: String {
    switch self {
    case .scn: return "Editable SceneKit scene"
    case .usdz: return "AR Quick Look and spatial apps"
    case .usd: return "Universal Scene Description"
    case .dae: return "Broad 3D app compatibility"
    case .obj: return "Widely supported mesh format"
    case .stl: return "3D printing; geometry only"
    case .ply: return "Mesh data; useful for fabrication tools"
    case .abc: return "VFX and DCC pipelines"
    }
  }
}
