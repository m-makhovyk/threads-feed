import UIKit

class SwipeToDismissInteraction: NSObject {

  private weak var viewController: ImagePreviewViewController?
  private weak var backgroundView: UIView?
  private weak var closeButton: UIView?

  private let dismissThreshold: CGFloat = 100
  private let velocityThreshold: CGFloat = 800
  private let maxScaleReduction: CGFloat = 0.2
  private let maxCornerRadius: CGFloat = 24
  private let maxDistance: CGFloat = 300

  private var snapshotView: UIImageView?
  private var sourceFrame: CGRect = .zero

  init(
    viewController: ImagePreviewViewController,
    backgroundView: UIView,
    closeButton: UIView
  ) {
    self.viewController = viewController
    self.backgroundView = backgroundView
    self.closeButton = closeButton
    super.init()

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
    pan.delegate = self
    viewController.view.addGestureRecognizer(pan)
    viewController.collectionView.panGestureRecognizer.require(toFail: pan)
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard let viewController, let backgroundView else { return }
    let translation = gesture.translation(in: viewController.view)
    let distance = hypot(translation.x, translation.y)
    let progress = min(distance / maxDistance, 1.0)

    switch gesture.state {
    case .began:
      guard let image = viewController.currentImage else { return }
      closeButton?.alpha = 0
      sourceFrame = ImageZoomTransition.aspectFitFrame(for: image, in: viewController.view.bounds)

      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFit
      imageView.clipsToBounds = true
      imageView.layer.cornerCurve = .continuous
      imageView.frame = sourceFrame
      viewController.view.addSubview(imageView)
      snapshotView = imageView

      viewController.collectionView.isHidden = true

    case .changed:
      guard let snapshotView else { return }
      let scale = 1.0 - progress * maxScaleReduction
      snapshotView.transform = CGAffineTransform(scaleX: scale, y: scale)
        .concatenating(CGAffineTransform(translationX: translation.x, y: translation.y))
      snapshotView.layer.cornerRadius = progress * maxCornerRadius
      backgroundView.alpha = 1 - progress

    case .ended, .cancelled:
      guard let snapshotView else { return }
      let velocity = gesture.velocity(in: viewController.view)
      let speed = hypot(velocity.x, velocity.y)
      let shouldDismiss = distance >= dismissThreshold || speed >= velocityThreshold

      if shouldDismiss {
        let image = viewController.currentImage
        let sourceInfo = image != nil
          ? viewController.zoomTransition.sourceProvider?(viewController.currentPage)
          : nil

        if let image, let sourceInfo {
          animateDismissToSource(image: image, sourceInfo: sourceInfo, translation: translation, progress: progress)
        } else {
          let translationX = translation.x + velocity.x * 0.15
          let translationY = translation.y + velocity.y * 0.15

          UIView.animate(withDuration: 0.25, animations: {
            snapshotView.transform = CGAffineTransform(translationX: translationX, y: translationY)
            snapshotView.alpha = 0
            backgroundView.alpha = 0
          }) { _ in
            self.cleanup()
            viewController.dismiss(animated: false)
          }
        }
      } else {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
          snapshotView.transform = .identity
          snapshotView.layer.cornerRadius = 0
          backgroundView.alpha = 1
        } completion: { _ in
          viewController.collectionView.isHidden = false
          self.cleanup()
        }
        UIView.animate(withDuration: 0.2, delay: 0.15) {
          self.closeButton?.alpha = 1
        }
      }

    default:
      break
    }
  }

  private func animateDismissToSource(
    image: UIImage,
    sourceInfo: ImageZoomTransition.SourceInfo,
    translation: CGPoint,
    progress: CGFloat
  ) {
    guard let viewController, let backgroundView else { return }

    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: viewController.view)
    let currentScale = 1.0 - progress * maxScaleReduction
    let visualFrame = CGRect(
      x: sourceFrame.midX + translation.x - sourceFrame.width * currentScale / 2,
      y: sourceFrame.midY + translation.y - sourceFrame.height * currentScale / 2,
      width: sourceFrame.width * currentScale,
      height: sourceFrame.height * currentScale
    )
    let currentCornerRadius = snapshotView?.layer.cornerRadius ?? 0

    snapshotView?.removeFromSuperview()
    snapshotView = nil
    sourceInfo.view.alpha = 0

    let start = ImageZoomTransition.Endpoint(
      frame: visualFrame,
      imageSize: ImageZoomTransition.aspectFitSize(for: image, in: visualFrame.size),
      cornerRadius: currentCornerRadius
    )
    let end = ImageZoomTransition.Endpoint(
      frame: cellFrame,
      imageSize: ImageZoomTransition.aspectFillSize(for: image, in: cellFrame.size),
      cornerRadius: sourceInfo.cornerRadius
    )

    ImageZoomTransition.animateClipTransition(
      image: image,
      from: start,
      to: end,
      in: viewController.view,
      alongside: {
        backgroundView.alpha = 0
      },
      completion: {
        sourceInfo.view.alpha = 1
        viewController.dismiss(animated: false)
      }
    )
  }

  private func cleanup() {
    snapshotView?.removeFromSuperview()
    snapshotView = nil
  }
}

extension SwipeToDismissInteraction: UIGestureRecognizerDelegate {

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    guard viewController?.currentCell?.isZoomed != true else { return false }

    let velocity = pan.velocity(in: viewController?.view)
    return canStartDismiss(with: velocity)
  }

  private func canStartDismiss(with velocity: CGPoint) -> Bool {
    guard let viewController else { return false }

    if abs(velocity.y) > abs(velocity.x) {
      return true
    }

    if viewController.imageCount <= 1 {
      return true
    }

    let isFirstPage = viewController.currentPage == 0

    if velocity.x > 0 {
      return isFirstPage
    }

    return false
  }
}
