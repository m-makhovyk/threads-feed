import UIKit
import SnapKit
import NukeUI

class ImageAttachmentsView: UIView {

  // 16 (cell padding) + 40 (avatar) + 10 (gap)
  static let leadingInset: CGFloat = 16 + 40 + 10
  static let imageCornerRadius: CGFloat = 12

  var onImageTapped: ((_ urls: [URL], _ index: Int) -> Void)?

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private var urls: [URL] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.alwaysBounceHorizontal = true
    addSubview(scrollView)

    scrollView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    stackView.axis = .horizontal
    stackView.spacing = 8
    scrollView.addSubview(stackView)

    stackView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
      make.height.equalToSuperview()
    }

    scrollView.contentInset = UIEdgeInsets(
      top: 0,
      left: Self.leadingInset,
      bottom: 0,
      right: 16
    )
  }

  func configure(with urls: [URL]) {
    self.urls = urls
    stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    scrollView.contentOffset = CGPoint(x: -Self.leadingInset, y: 0)
    scrollView.isScrollEnabled = urls.count > 1

    for (index, url) in urls.enumerated() {
      let imageView = LazyImageView()
      imageView.placeholderView = makePlaceholder()
      imageView.url = url
      imageView.imageView.contentMode = .scaleAspectFill
      imageView.clipsToBounds = true
      imageView.layer.cornerRadius = Self.imageCornerRadius
      imageView.isUserInteractionEnabled = true
      imageView.tag = index

      let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
      imageView.addGestureRecognizer(tap)

      imageView.snp.makeConstraints { make in
        make.width.equalTo(280)
      }

      stackView.addArrangedSubview(imageView)
    }
  }

  @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
    guard let view = gesture.view else { return }
    onImageTapped?(urls, view.tag)
  }

  func imageView(at index: Int) -> UIView? {
    guard index >= 0, index < stackView.arrangedSubviews.count else { return nil }
    return stackView.arrangedSubviews[index]
  }

  func image(at index: Int) -> UIImage? {
    guard let lazyImageView = imageView(at: index) as? LazyImageView else { return nil }
    return lazyImageView.imageView.image
  }

  private func makePlaceholder() -> UIView {
    let view = UIView()
    view.backgroundColor = .secondarySystemBackground
    view.layer.cornerRadius = Self.imageCornerRadius
    return view
  }
}
