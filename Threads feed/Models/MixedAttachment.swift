import Foundation

enum MixedAttachment {
  case image(ImageAttachment)
  case video(VideoAttachment)

  var width: Int {
    switch self {
    case .image(let a): return a.width
    case .video(let a): return a.width
    }
  }

  var height: Int {
    switch self {
    case .image(let a): return a.height
    case .video(let a): return a.height
    }
  }

  var aspectRatio: CGFloat {
    CGFloat(width) / CGFloat(height)
  }
}
