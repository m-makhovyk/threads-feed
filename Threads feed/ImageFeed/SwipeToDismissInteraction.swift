import UIKit

class SwipeToDismissInteraction: NSObject {

  private weak var viewController: ImagePreviewViewController?
  private weak var backgroundView: UIView?
  private weak var closeButton: UIView?

  // Diagonal drag distance past which the gesture commits to dismissing on release.
  private let dismissThreshold: CGFloat = 100
  private let velocityThreshold: CGFloat = 800
  private let maxScaleReduction: CGFloat = 0.2
  private let maxCornerRadius: CGFloat = 24
  // Diagonal drag distance at which scale/corner/background-alpha effects saturate;
  // dragging further keeps moving the image but stops changing those visuals.
  private let maxDistance: CGFloat = 300

  private var panGesture: UIPanGestureRecognizer!
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
    panGesture = pan
  }

  func disable() {
    panGesture.isEnabled = false
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
      sourceFrame = AspectGeometry.aspectFitFrame(contentSize: image.size, boundingRect: viewController.view.bounds)

      let imageView = makeImageMirror(image: image)
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
        panGesture.isEnabled = false

        if let image = viewController.currentImage,
           let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage) {
          viewController.zoomTransition.finishInteractiveDismiss(
            image: image,
            sourceInfo: sourceInfo,
            visualFrameInPreview: snapshotView.frame,
            cornerRadius: snapshotView.layer.cornerRadius,
            viewController: viewController
          )
        } else {
          viewController.onClearBlackout?()
          viewController.dismiss(animated: false)
        }
        self.snapshotView = nil
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

  private func makeImageMirror(image: UIImage) -> UIImageView {
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = true
    imageView.layer.cornerCurve = .continuous
    imageView.frame = sourceFrame
    return imageView
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
