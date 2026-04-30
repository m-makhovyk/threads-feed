import UIKit

class ImageZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

  struct SourceInfo {
    let view: UIView
    let image: UIImage
    let cornerRadius: CGFloat
  }

  struct Endpoint {
    let frame: CGRect
    let imageSize: CGSize
    let cornerRadius: CGFloat
    let imageFrame: CGRect?

    init(
      frame: CGRect,
      imageSize: CGSize,
      cornerRadius: CGFloat,
      imageFrame: CGRect? = nil
    ) {
      self.frame = frame
      self.imageSize = imageSize
      self.cornerRadius = cornerRadius
      self.imageFrame = imageFrame
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

    let screenBounds = toVC.view.bounds
    toVC.backgroundView.alpha = 0
    toVC.collectionView.alpha = 0
    toVC.closeButton.alpha = 0
    sourceInfo.view.alpha = 0
    toVC.onBlackoutIndex?(toVC.initialIndex)

    let start = Endpoint(
      frame: cellFrame,
      imageSize: AspectGeometry.aspectFillSize(contentSize: image.size, boundingSize: cellFrame.size),
      cornerRadius: sourceInfo.cornerRadius
    )
    let end = Endpoint(
      frame: screenBounds,
      imageSize: AspectGeometry.aspectFitSize(contentSize: image.size, boundingSize: screenBounds.size),
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
    imageView.frame = start.imageFrame ?? centeredRect(size: start.imageSize, in: start.frame.size)
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
      imageView.frame = end.imageFrame ?? centeredRect(size: end.imageSize, in: end.frame.size)
      imageView.layer.cornerRadius = 0
      alongside()
    } completion: { _ in
      clipView.removeFromSuperview()
      completion()
    }
  }

  private static func centeredRect(size: CGSize, in containerSize: CGSize) -> CGRect {
    CGRect(
      x: (containerSize.width - size.width) / 2,
      y: (containerSize.height - size.height) / 2,
      width: size.width,
      height: size.height
    )
  }
}
