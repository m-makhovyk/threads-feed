import UIKit

enum ImagePreviewDismissAnimator {

  static func dismiss(from viewController: ImagePreviewViewController) {
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
      visualFrameInPreview: viewController.view.bounds,
      cornerRadius: 0,
      imageFrameInPreview: viewController.currentCell?.imageFrame(in: viewController.view),
      in: viewController.view,
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
    let clearBlackout = viewController.onClearBlackout

    guard let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    runDismissClipAnimation(
      image: image,
      sourceInfo: sourceInfo,
      feedCollectionView: feedCollectionView,
      visualFrameInPreview: visualFrameInPreview,
      cornerRadius: cornerRadius,
      in: viewController.view,
      completion: { clearBlackout?() }
    )

    viewController.dismiss(animated: false)
  }

  private static func runDismissClipAnimation(
    image: UIImage,
    sourceInfo: ImageZoomTransition.SourceInfo,
    feedCollectionView: UICollectionView,
    visualFrameInPreview: CGRect,
    cornerRadius: CGFloat,
    imageFrameInPreview: CGRect? = nil,
    in previewView: UIView,
    completion: @escaping () -> Void
  ) {
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCollectionView)
    let visualFrame = feedCollectionView.convert(visualFrameInPreview, from: previewView)

    // If the caller provided a custom on-screen image rect (e.g. zoomed/panned), re-express it
    // relative to `visualFrame` so the animation starts exactly where the image is drawn.
    let startImageFrame = imageFrameInPreview.map { rect in
      let inFeed = feedCollectionView.convert(rect, from: previewView)
      return inFeed.offsetBy(dx: -visualFrame.minX, dy: -visualFrame.minY)
    }

    let start = ImageZoomTransition.Endpoint(
      frame: visualFrame,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
      cornerRadius: cornerRadius,
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
