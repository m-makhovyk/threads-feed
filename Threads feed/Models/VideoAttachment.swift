import Foundation

struct VideoAttachment {
  let url: URL
  let width: Int
  let height: Int
  let duration: TimeInterval

  var aspectRatio: CGFloat {
    CGFloat(width) / CGFloat(height)
  }
}
