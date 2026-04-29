import Foundation
import UIKit

final class ImagePreviewDismissAnimator {

  func dismissFromCurrentPreviewImage(from viewController: ImagePreviewViewController) {

    let image = viewController.currentImage
    let sourceInfo = viewController.zoomTransition.sourceProvider?(viewController.currentPage)
    let clearBlackout = viewController.onClearBlackout

    // Start clip animation on feed (behind preview, not visible yet)
    if let image, let sourceInfo,
       let feedCV = sourceInfo.view.findOutermostCollectionView() {
      let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCV)
      let visualFrame = feedCV.convert(viewController.view.bounds, from: nil)

      let start = ImageZoomTransition.Endpoint(
        frame: visualFrame,
        imageSize: ImageZoomTransition.aspectFitSize(for: image, in: visualFrame.size),
        cornerRadius: 0
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
        in: feedCV,
        completion: {
          clearBlackout?()
        }
      )
    } else {
      clearBlackout?()
    }

    viewController.dismiss(animated: false)
  }
}
