import UIKit

class ImageZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

  struct SourceInfo {
    let view: UIView
    let image: UIImage
    let cornerRadius: CGFloat
  }

  struct Endpoint {
    let frame: CGRect
    let imageFrame: CGRect
    let cornerRadius: CGFloat

    static func centered(
      frame: CGRect,
      imageSize: CGSize,
      cornerRadius: CGFloat
    ) -> Self {
      Endpoint(
        frame: frame,
        imageFrame: AspectGeometry.centeredRect(size: imageSize, in: frame.size),
        cornerRadius: cornerRadius
      )
    }
  }

  static let animationDuration: TimeInterval = 0.45

  var sourceProvider: ((_ pageIndex: Int) -> SourceInfo?)?

  func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
    Self.animationDuration
  }

  func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    animatePresentation(using: transitionContext)
  }

  // MARK: - Present

  private func animatePresentation(using context: UIViewControllerContextTransitioning) {
    guard
      let toVC = context.viewController(forKey: .to) as? ImagePreviewViewController,
      let sourceInfo = sourceProvider?(toVC.initialIndex)
    else {
      if let toVC = context.viewController(forKey: .to) {
        context.containerView.addSubview(toVC.view)
        toVC.view.frame = context.finalFrame(for: toVC)
      }
      context.completeTransition(true)
      return
    }

    let containerView = context.containerView
    let image = sourceInfo.image
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: containerView)

    toVC.view.frame = context.finalFrame(for: toVC)
    containerView.addSubview(toVC.view)
    toVC.view.layoutIfNeeded()

    let previewBounds = toVC.view.bounds
    toVC.backgroundView.alpha = 0
    toVC.collectionView.alpha = 0
    toVC.closeButton.alpha = 0
    sourceInfo.view.alpha = 0
    toVC.onBlackoutIndex?(toVC.initialIndex)

    let start = Endpoint.centered(
      frame: cellFrame,
      imageSize: AspectGeometry.aspectFillSize(contentSize: image.size, boundingSize: cellFrame.size),
      cornerRadius: sourceInfo.cornerRadius
    )
    let end = Endpoint.centered(
      frame: previewBounds,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: previewBounds.size),
      cornerRadius: sourceInfo.cornerRadius
    )

    Self.animateClipTransition(
      image: image,
      from: start,
      to: end,
      in: containerView,
      duration: transitionDuration(using: context),
      alongside: {
        toVC.backgroundView.alpha = 1
      },
      completion: {
        let completed = !context.transitionWasCancelled
        if completed {
          toVC.collectionView.alpha = 1
          UIView.animate(withDuration: 0.1, delay: 0) {
            toVC.closeButton.alpha = 1
          }
        }
        sourceInfo.view.alpha = 1
        context.completeTransition(completed)
      }
    )
  }

  // MARK: - Dismiss

  func dismiss(from viewController: ImagePreviewViewController) {
    let clearBlackout = viewController.onClearBlackout

    guard let image = viewController.currentImage,
          let sourceInfo = sourceProvider?(viewController.currentPage),
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

  func finishInteractiveDismiss(
    image: UIImage,
    sourceInfo: SourceInfo,
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

  private func runDismissClipAnimation(
    image: UIImage,
    sourceInfo: SourceInfo,
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

    let start: Endpoint = if let startImageFrame {
      Endpoint(
        frame: visualFrame,
        imageFrame: startImageFrame,
        cornerRadius: cornerRadius
      )
    } else {
      .centered(
        frame: visualFrame,
        imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: visualFrame.size),
        cornerRadius: cornerRadius
      )
    }
    let end = Endpoint.centered(
      frame: cellFrame,
      imageSize: AspectGeometry.aspectFillSize(contentSize: image.size, boundingSize: cellFrame.size),
      cornerRadius: sourceInfo.cornerRadius
    )

    Self.animateClipTransition(
      image: image,
      from: start,
      to: end,
      in: feedCollectionView,
      completion: completion
    )
  }

  // MARK: - Shared Animation

  static func animateClipTransition(
    image: UIImage,
    from start: Endpoint,
    to end: Endpoint,
    in containerView: UIView,
    duration: TimeInterval = ImageZoomTransition.animationDuration,
    alongside: @escaping () -> Void = {},
    completion: @escaping () -> Void = {}
  ) {
    let clipView = UIView(frame: start.frame)
    clipView.clipsToBounds = true
    clipView.layer.cornerRadius = start.cornerRadius
    clipView.layer.cornerCurve = .continuous
    containerView.addSubview(clipView)

    let imageView = UIImageView(image: image)
    imageView.frame = start.imageFrame
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = end.cornerRadius
    clipView.addSubview(imageView)

    UIView.animate(
      withDuration: duration,
      delay: 0,
      usingSpringWithDamping: 0.85,
      initialSpringVelocity: 0
    ) {
      clipView.frame = end.frame
      clipView.layer.cornerRadius = end.cornerRadius
      imageView.frame = end.imageFrame
      imageView.layer.cornerRadius = 0
      alongside()
    } completion: { _ in
      clipView.removeFromSuperview()
      completion()
    }
  }
}
