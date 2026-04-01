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
      sourceFrame = Self.aspectFitFrame(for: image, in: viewController.view.bounds)

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
      snapshotView.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
        .scaledBy(x: scale, y: scale)
      snapshotView.layer.cornerRadius = progress * maxCornerRadius
      backgroundView.alpha = 1 - progress

    case .ended, .cancelled:
      guard let snapshotView else { return }
      let velocity = gesture.velocity(in: viewController.view)
      let speed = hypot(velocity.x, velocity.y)
      let shouldDismiss = distance >= dismissThreshold || speed >= velocityThreshold

      if shouldDismiss {
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

  private func cleanup() {
    snapshotView?.removeFromSuperview()
    snapshotView = nil
  }

  private static func aspectFitFrame(for image: UIImage, in bounds: CGRect) -> CGRect {
    let imageRatio = image.size.width / image.size.height
    let boundsRatio = bounds.width / bounds.height
    let size: CGSize
    if imageRatio > boundsRatio {
      size = CGSize(width: bounds.width, height: bounds.width / imageRatio)
    } else {
      size = CGSize(width: bounds.height * imageRatio, height: bounds.height)
    }
    return CGRect(
      x: (bounds.width - size.width) / 2,
      y: (bounds.height - size.height) / 2,
      width: size.width,
      height: size.height
    )
  }
}

extension SwipeToDismissInteraction: UIGestureRecognizerDelegate {

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: viewController?.view)
    return abs(velocity.y) > abs(velocity.x)
  }
}
