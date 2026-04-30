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

    // The clip animation runs on the feed collection view, hidden behind the preview;
    // the preview is dismissed instantly at the end so the user only sees the animation.
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCollectionView)
    let visualFrame = feedCollectionView.convert(viewController.view.bounds, from: viewController.view)
    // If a preview cell is available, capture the actual on-screen image rect (which may be zoomed/panned)
    // expressed relative to `visualFrame`. `nil` means "no custom placement, fall back to aspect-fit".
    let startImageFrame = viewController.currentCell.map { cell in
      let imageFrameInPreview = cell.imageFrame(in: viewController.view)
      let imageFrame = feedCollectionView.convert(imageFrameInPreview, from: viewController.view)
      return imageFrame.offsetBy(dx: -visualFrame.minX, dy: -visualFrame.minY)
    }

    // Starting endpoint: full-screen, aspect-fit, no rounding. `imageFrame` carries the user's
    // current zoom/pan so the animation begins exactly where the image is drawn on screen.
    let start = ImageZoomTransition.Endpoint(
      frame: visualFrame,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
      cornerRadius: 0,
      imageFrame: startImageFrame
    )
    // Ending endpoint: the thumbnail cell, aspect-fill, with the cell's corner radius.
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

  func finishInteractiveDismiss(
    image: UIImage,
    sourceInfo: ImageZoomTransition.SourceInfo,
    initialSnapshotFrame: CGRect,
    translation: CGPoint,
    scale: CGFloat,
    cornerRadius: CGFloat,
    viewController: ImagePreviewViewController
  ) {
    guard let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      viewController.onClearBlackout?()
      return
    }

    let clearBlackout = viewController.onClearBlackout

    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCollectionView)
    let visualFrameInPreview = CGRect(
      x: initialSnapshotFrame.midX + translation.x - initialSnapshotFrame.width * scale / 2,
      y: initialSnapshotFrame.midY + translation.y - initialSnapshotFrame.height * scale / 2,
      width: initialSnapshotFrame.width * scale,
      height: initialSnapshotFrame.height * scale
    )
    let visualFrame = feedCollectionView.convert(visualFrameInPreview, from: viewController.view)

    let start = ImageZoomTransition.Endpoint(
      frame: visualFrame,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
      cornerRadius: cornerRadius
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
        clearBlackout?()
      }
    )
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
