import UIKit
import Nuke

class ZoomableImageCell: UICollectionViewCell {

  static let reuseID = "ZoomableImageCell"

  var isZoomed: Bool {
    scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
  }

  private let scrollView = UIScrollView()
  private let imageContainerView = UIView()
  private(set) var imageView = UIImageView()
  private var imageTask: ImageTask?
  private var currentURL: URL?

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 4.0
    scrollView.bounces = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.frame = contentView.bounds
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.addSubview(scrollView)

    imageContainerView.frame = scrollView.bounds
    scrollView.addSubview(imageContainerView)

    imageView.contentMode = .scaleToFill
    imageView.frame = imageContainerView.bounds
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageContainerView.addSubview(imageView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    guard !isZoomed else { return }
    updateImageLayout()
  }

  func configure(with url: URL) {
    currentURL = url
    imageTask?.cancel()
    imageView.image = nil
    resetZoom()

    imageTask = ImagePipeline.shared.loadImage(with: url) { [weak self] result in
      guard let self else { return }
      guard self.currentURL == url else { return }

      self.imageTask = nil

      if case .success(let response) = result {
        self.imageView.image = response.image
        self.updateImageLayout()
      }
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageTask?.cancel()
    imageTask = nil
    currentURL = nil
    imageView.image = nil
    resetZoom()
  }

  private func resetZoom() {
    scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    updateImageLayout()
  }

  private func updateImageLayout() {
    let boundsSize = scrollView.bounds.size
    guard boundsSize.width > 0, boundsSize.height > 0 else { return }

    let imageSize: CGSize
    if let image = imageView.image, image.size.width > 0, image.size.height > 0 {
      imageSize = aspectFitSize(for: image.size, in: boundsSize)
    } else {
      imageSize = boundsSize
    }

    let contentSize = CGSize(
      width: max(imageSize.width, boundsSize.width),
      height: max(imageSize.height, boundsSize.height)
    )

    scrollView.contentSize = contentSize
    imageContainerView.frame = CGRect(
      x: (contentSize.width - imageSize.width) / 2,
      y: (contentSize.height - imageSize.height) / 2,
      width: imageSize.width,
      height: imageSize.height
    )
    imageView.frame = imageContainerView.bounds
  }

  private func aspectFitSize(for imageSize: CGSize, in boundsSize: CGSize) -> CGSize {
    let imageRatio = imageSize.width / imageSize.height
    let boundsRatio = boundsSize.width / boundsSize.height

    if imageRatio > boundsRatio {
      return CGSize(width: boundsSize.width, height: boundsSize.width / imageRatio)
    } else {
      return CGSize(width: boundsSize.height * imageRatio, height: boundsSize.height)
    }
  }
}

extension ZoomableImageCell: UIScrollViewDelegate {

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageContainerView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
    let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)

    imageContainerView.center = CGPoint(
      x: scrollView.contentSize.width / 2 + offsetX,
      y: scrollView.contentSize.height / 2 + offsetY
    )
  }
}
