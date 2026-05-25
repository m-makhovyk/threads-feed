import UIKit
import AVFoundation

class VideoSwipeToDismissInteraction: NSObject {

  private enum AnimationConstants {
    static let springBackDuration: TimeInterval = 0.3
    static let springBackDamping: CGFloat = 0.8
    static let controlsFadeDuration: TimeInterval = 0.2
    static let controlsFadeDelay: TimeInterval = 0.15
  }

  var onControlsVisible: ((Bool) -> Void)?

  private weak var viewController: VideoPreviewViewController?
  private weak var backgroundView: UIView?

  private let dismissThreshold: CGFloat = 100
  private let velocityThreshold: CGFloat = 800
  private let maxScaleReduction: CGFloat = 0.2
  private let maxCornerRadius: CGFloat = 24
  private let maxDistance: CGFloat = 300

  private var panGesture: UIPanGestureRecognizer!
  private var mirrorView: VideoPlayerView?
  private weak var sourceCell: FullScreenVideoCell?

  init(
    viewController: VideoPreviewViewController,
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
      guard let cell = viewController.currentCell else { return }
      onControlsVisible?(false)

      let attachment = viewController.attachment(at: viewController.currentPage)
      let contentSize = CGSize(width: attachment.width, height: attachment.height)
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
      mirrorView = playerView
      sourceCell = cell

      viewController.collectionView.isHidden = true

    case .changed:
      guard let mirrorView else { return }
      let scale = 1.0 - progress * maxScaleReduction
      mirrorView.transform = CGAffineTransform(scaleX: scale, y: scale)
        .concatenating(CGAffineTransform(translationX: translation.x, y: translation.y))
      mirrorView.layer.cornerRadius = progress * maxCornerRadius
      backgroundView.alpha = 1 - progress

    case .ended, .cancelled:
      guard let mirrorView else { return }
      let velocity = gesture.velocity(in: viewController.view)
      let speed = hypot(velocity.x, velocity.y)
      let shouldDismiss = distance >= dismissThreshold || speed >= velocityThreshold

      if shouldDismiss {
        panGesture.isEnabled = false

        let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage)
        let playerContext = viewController.currentPlayerContext()
        let currentCornerRadius = mirrorView.layer.cornerRadius
        let visualFrame = mirrorView.frame

        if let playerContext, let sourceInfo {
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
        self.mirrorView = nil
        self.sourceCell = nil
      } else {
        panGesture.isEnabled = false
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
          self.sourceCell?.restorePlayerView()
          self.mirrorView = nil
          self.sourceCell = nil
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

extension VideoSwipeToDismissInteraction: UIGestureRecognizerDelegate {

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }

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
