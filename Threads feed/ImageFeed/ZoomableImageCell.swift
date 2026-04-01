import UIKit
import Nuke

class ZoomableImageCell: UICollectionViewCell {

  static let reuseID = "ZoomableImageCell"

  private let scrollView = UIScrollView()
  private let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 4.0
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.frame = contentView.bounds
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.addSubview(scrollView)

    imageView.contentMode = .scaleAspectFit
    imageView.frame = scrollView.bounds
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scrollView.addSubview(imageView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with url: URL) {
    ImagePipeline.shared.loadImage(with: url) { [weak self] result in
      if case .success(let response) = result {
        self?.imageView.image = response.image
      }
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    scrollView.zoomScale = 1.0
    imageView.image = nil
  }
}

extension ZoomableImageCell: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
    let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
    imageView.center = CGPoint(
      x: scrollView.contentSize.width / 2 + offsetX,
      y: scrollView.contentSize.height / 2 + offsetY
    )
  }

  func scrollViewDidEndZooming(
    _ scrollView: UIScrollView,
    with view: UIView?,
    atScale scale: CGFloat
  ) {
    UIView.animate(withDuration: 0.25) {
      scrollView.zoomScale = 1.0
    }
  }
}
