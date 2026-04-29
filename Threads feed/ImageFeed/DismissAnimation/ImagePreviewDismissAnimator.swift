import Foundation
import UIKit

final class ImagePreviewDismissAnimator {

  func dismissFromCurrentPreviewImage(from viewController: ImagePreviewViewController) {

    let image = viewController.currentImage
    let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage)
    let completion = viewController.onClearBlackout

    // Start clip animation on feed (behind preview, not visible yet)
    if let image, let sourceInfo,
       let feedCV = sourceInfo.view.findOutermostCollectionView() {
      let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCV)
      let visualFrame = feedCV.convert(viewController.view.bounds, from: viewController.view)

      let start = ImageZoomTransition.Endpoint(
        frame: visualFrame,
        imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
        cornerRadius: 0
      )
      let end = ImageZoomTransition.Endpoint(
        frame: cellFrame,
        imageSize: AspectGeometry.aspectFillSize(contentSize: image.size, boundingSize: cellFrame.size),
        cornerRadius: sourceInfo.cornerRadius
      )

      ImageZoomTransition.animateClipTransition(
        image: image,
        from: start,
        to: end,
        in: feedCV,
        completion: {
          completion?()
        }
      )
    } else {
      completion?()
    }

    viewController.dismiss(animated: false)
  }
}


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
}
