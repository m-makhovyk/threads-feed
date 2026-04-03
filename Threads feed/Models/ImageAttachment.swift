import Foundation

struct ImageAttachment {
  let url: URL
  let width: Int
  let height: Int

  var aspectRatio: CGFloat {
    CGFloat(width) / CGFloat(height)
  }
}
