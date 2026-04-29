import Foundation
import UIKit

final class ImagePreviewDismissAnimator {

  func dismissFromCurrentPreviewImage(from viewController: ImagePreviewViewController) {
    let completion = viewController.onClearBlackout

    guard let image = viewController.currentImage,
          let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage),
          let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      completion?()
      viewController.dismiss(animated: false)
      return
    }

    // Start clip animation on feed (behind preview, not visible yet)
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCollectionView)
    let visualFrame = feedCollectionView.convert(viewController.view.bounds, from: viewController.view)
    let startImageFrame = viewController.currentCell.map { cell in
      let imageFrameInPreview = cell.imageFrame(in: viewController.view)
      let imageFrame = feedCollectionView.convert(imageFrameInPreview, from: viewController.view)
      return imageFrame.offsetBy(dx: -visualFrame.minX, dy: -visualFrame.minY)
    }

    let start = ImageZoomTransition.Endpoint(
      frame: visualFrame,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
      cornerRadius: 0,
      imageFrame: startImageFrame
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
      in: feedCollectionView,
      completion: {
        completion?()
      }
    )

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
