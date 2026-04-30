import Foundation
import UIKit

enum ImagePreviewDismissAnimator {

  static func dismissFromCurrentPreviewImage(from viewController: ImagePreviewViewController) {
    let clearBlackout = viewController.onClearBlackout

    guard let image = viewController.currentImage,
          let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage),
          let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    runDismissClipAnimation(
      image: image,
      sourceInfo: sourceInfo,
      feedCollectionView: feedCollectionView,
      startVisualFrameInPreview: viewController.view.bounds,
      startCornerRadius: 0,
      startImageFrameInPreview: viewController.currentCell?.imageFrame(in: viewController.view),
      in: viewController,
      completion: { clearBlackout?() }
    )

    viewController.dismiss(animated: false)
  }

  static func finishInteractiveDismiss(
    image: UIImage,
    sourceInfo: ImageZoomTransition.SourceInfo,
    visualFrameInPreview: CGRect,
    cornerRadius: CGFloat,
    viewController: ImagePreviewViewController
  ) {
    guard let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      viewController.onClearBlackout?()
      return
    }

    let clearBlackout = viewController.onClearBlackout

    runDismissClipAnimation(
      image: image,
      sourceInfo: sourceInfo,
      feedCollectionView: feedCollectionView,
      startVisualFrameInPreview: visualFrameInPreview,
      startCornerRadius: cornerRadius,
      in: viewController,
      completion: { clearBlackout?() }
    )
  }

  private static func runDismissClipAnimation(
    image: UIImage,
    sourceInfo: ImageZoomTransition.SourceInfo,
    feedCollectionView: UICollectionView,
    startVisualFrameInPreview: CGRect,
    startCornerRadius: CGFloat,
    startImageFrameInPreview: CGRect? = nil,
    in viewController: ImagePreviewViewController,
    completion: @escaping () -> Void
  ) {
    // The clip animation runs on the feed collection view, hidden behind the preview;
    // the preview is dismissed instantly at the end so the user only sees the animation.
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCollectionView)
    let visualFrame = feedCollectionView.convert(startVisualFrameInPreview, from: viewController.view)

    // If the caller provided a custom on-screen image rect (e.g. zoomed/panned), re-express it
    // relative to `visualFrame` so the animation starts exactly where the image is drawn.
    let startImageFrame = startImageFrameInPreview.map { rect in
      let inFeed = feedCollectionView.convert(rect, from: viewController.view)
      return inFeed.offsetBy(dx: -visualFrame.minX, dy: -visualFrame.minY)
    }

    let start = ImageZoomTransition.Endpoint(
      frame: visualFrame,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
      cornerRadius: startCornerRadius,
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
      completion: completion
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
