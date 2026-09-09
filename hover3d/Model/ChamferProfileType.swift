import AppKit

enum ChamferProfileType: Equatable {
  case straight
  case curvedIn
  case curvedOut
  case tildaIn
  case tildaOut

  func getBezierPath() -> NSBezierPath {
    switch self {
    case .straight: return .straight
    case .curvedIn: return .curvedIn
    case .curvedOut: return .curvedOut
    case .tildaIn: return .tildaIn
    case .tildaOut: return .tildaOut
    }
  }
}
