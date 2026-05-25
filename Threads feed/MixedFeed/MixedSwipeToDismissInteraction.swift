import UIKit
import AVFoundation

class MixedSwipeToDismissInteraction: NSObject {

  private enum AnimationConstants {
    static let springBackDuration: TimeInterval = 0.3
    static let springBackDamping: CGFloat = 0.8
    static let controlsFadeDuration: TimeInterval = 0.2
    static let controlsFadeDelay: TimeInterval = 0.15
  }

  private enum Mirror {
    case image(UIImageView)
    case video(VideoPlayerView, FullScreenMixedVideoCell)

    var view: UIView {
      switch self {
      case .image(let v): return v
      case .video(let v, _): return v
      }
    }
  }

  var onControlsVisible: ((Bool) -> Void)?

  private weak var viewController: MixedPreviewViewController?
  private weak var backgroundView: UIView?

  private let dismissThreshold: CGFloat = 100
  private let velocityThreshold: CGFloat = 800
  private let maxScaleReduction: CGFloat = 0.2
  private let maxCornerRadius: CGFloat = 24
  private let maxDistance: CGFloat = 300

  private var panGesture: UIPanGestureRecognizer!
  private var mirror: Mirror?

  init(
    viewController: MixedPreviewViewController,
    backgroundView: UIView
  ) {
    self.viewController = viewController
    self.backgroundView = backgroundView
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
      onControlsVisible?(false)
      let attachment = viewController.attachment(at: viewController.currentPage)
      switch attachment {
      case .image:
        guard let image = viewController.currentImage(at: viewController.currentPage) else { return }
        let frame = AspectGeometry.aspectFitFrame(
          contentSize: image.size,
          boundingRect: viewController.view.bounds
        )
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerCurve = .continuous
        imageView.frame = frame
        viewController.view.addSubview(imageView)
        mirror = .image(imageView)

      case .video(let videoAttachment):
        guard let cell = viewController.currentVideoCell else { return }
        let contentSize = CGSize(width: videoAttachment.width, height: videoAttachment.height)
        let videoFrame = AspectGeometry.aspectFitFrame(
          contentSize: contentSize,
          boundingRect: viewController.view.bounds
        )
        let playerView = cell.extractPlayerView()
        playerView.frame = videoFrame
        playerView.backgroundColor = .clear
        playerView.layer.masksToBounds = true
        playerView.layer.cornerCurve = .continuous
        viewController.view.addSubview(playerView)
        mirror = .video(playerView, cell)
      }

      viewController.collectionView.isHidden = true

    case .changed:
      guard let mirror else { return }
      let scale = 1.0 - progress * maxScaleReduction
      mirror.view.transform = CGAffineTransform(scaleX: scale, y: scale)
        .concatenating(CGAffineTransform(translationX: translation.x, y: translation.y))
      mirror.view.layer.cornerRadius = progress * maxCornerRadius
      backgroundView.alpha = 1 - progress

    case .ended, .cancelled:
      guard let mirror else { return }
      let velocity = gesture.velocity(in: viewController.view)
      let speed = hypot(velocity.x, velocity.y)
      let shouldDismiss = distance >= dismissThreshold || speed >= velocityThreshold

      if shouldDismiss {
        panGesture.isEnabled = false
        let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage)
        let currentCornerRadius = mirror.view.layer.cornerRadius
        let visualFrame = mirror.view.frame

        switch mirror {
        case .image(let imageView):
          if let sourceInfo, case .image(let image) = sourceInfo.media {
            viewController.zoomTransition.finishInteractiveDismiss(
              image: image,
              sourceInfo: sourceInfo,
              visualFrameInPreview: visualFrame,
              cornerRadius: currentCornerRadius,
              viewController: viewController
            )
          } else {
            viewController.onClearBlackout?()
            viewController.dismiss(animated: false)
            imageView.removeFromSuperview()
          }

        case .video:
          let playerContext = viewController.currentPlayerContext()
          if let sourceInfo, let playerContext {
            viewController.zoomTransition.finishInteractiveDismiss(
              playerContext: playerContext,
              sourceInfo: sourceInfo,
              visualFrameInPreview: visualFrame,
              cornerRadius: currentCornerRadius,
              viewController: viewController
            )
          } else {
            viewController.onClearBlackout?()
            viewController.dismiss(animated: false)
          }
        }
        self.mirror = nil
      } else {
        panGesture.isEnabled = false
        let mirrorView = mirror.view
        UIView.animate(
          withDuration: AnimationConstants.springBackDuration,
          delay: 0,
          usingSpringWithDamping: AnimationConstants.springBackDamping,
          initialSpringVelocity: 0
        ) {
          mirrorView.transform = .identity
          mirrorView.layer.cornerRadius = 0
          backgroundView.alpha = 1
        } completion: { _ in
          viewController.collectionView.isHidden = false
          switch mirror {
          case .image(let imageView):
            imageView.removeFromSuperview()
          case .video(_, let cell):
            cell.restorePlayerView()
          }
          self.mirror = nil
          self.panGesture.isEnabled = true
        }
        UIView.animate(
          withDuration: AnimationConstants.controlsFadeDuration,
          delay: AnimationConstants.controlsFadeDelay
        ) {
          self.onControlsVisible?(true)
        }
      }

    default:
      break
    }
  }
}

extension MixedSwipeToDismissInteraction: UIGestureRecognizerDelegate {

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    guard viewController?.currentImageCell?.isZoomed != true else { return false }

    let velocity = pan.velocity(in: viewController?.view)
    return canStartDismiss(with: velocity)
  }

  private func canStartDismiss(with velocity: CGPoint) -> Bool {
    guard let viewController else { return false }

    if abs(velocity.y) > abs(velocity.x) {
      return true
    }

    if viewController.attachmentsCount <= 1 {
      return true
    }

    // Asymmetric on purpose: only a rightward swipe from the first page counts as a "back" gesture.
    // Leftward swipes on the last page fall through to the collection to match Threads behaviour.
    let isFirstPage = viewController.currentPage == 0

    if velocity.x > 0 {
      return isFirstPage
    }

    return false
  }
}
