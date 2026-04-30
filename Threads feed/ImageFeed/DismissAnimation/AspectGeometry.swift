import CoreGraphics

enum AspectGeometry {
  static func aspectFillSize(contentSize: CGSize, boundingSize: CGSize) -> CGSize {
    guard contentSize.height > 0, boundingSize.height > 0 else { return boundingSize }

    let contentSizeRatio = contentSize.width / contentSize.height
    let boundingSizeRatio = boundingSize.width / boundingSize.height

    if contentSizeRatio > boundingSizeRatio {
      return CGSize(width: boundingSize.height * contentSizeRatio, height: boundingSize.height)
    } else {
      return CGSize(width: boundingSize.width, height: boundingSize.width / contentSizeRatio)
    }
  }

  static func aspectFitSize(contentSize: CGSize, boundingSize: CGSize) -> CGSize {
    guard contentSize.height > 0, boundingSize.height > 0 else { return boundingSize }

    let contentSizeRatio = contentSize.width / contentSize.height
    let boundingSizeRatio = boundingSize.width / boundingSize.height

    if contentSizeRatio > boundingSizeRatio {
      return CGSize(width: boundingSize.width, height: boundingSize.width / contentSizeRatio)
    } else {
      return CGSize(width: boundingSize.height * contentSizeRatio, height: boundingSize.height)
    }
  }

  static func aspectFitFrame(contentSize: CGSize, boundingRect: CGRect) -> CGRect {
    let size = aspectFitSize(contentSize: contentSize, boundingSize: boundingRect.size)
    return CGRect(
      x: boundingRect.origin.x + (boundingRect.width - size.width) / 2,
      y: boundingRect.origin.y + (boundingRect.height - size.height) / 2,
      width: size.width,
      height: size.height
    )
  }
}
