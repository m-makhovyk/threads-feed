import UIKit
import SnapKit
import Nuke

class ImagePreviewViewController: UIViewController {

  private let imageURL: URL
  private let scrollView = UIScrollView()
  private let imageView = UIImageView()

  private let closeButton: UIButton = {
    let button = UIButton(type: .system)
    let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
    let image = UIImage(systemName: "xmark", withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .white
    button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    button.layer.cornerRadius = 20
    return button
  }()

  init(imageURL: URL) {
    self.imageURL = imageURL
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 4.0
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.frame = view.bounds
    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(scrollView)

    imageView.contentMode = .scaleAspectFit
    imageView.frame = scrollView.bounds
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    scrollView.addSubview(imageView)

    ImagePipeline.shared.loadImage(with: imageURL) { [weak self] result in
      if case .success(let response) = result {
        self?.imageView.image = response.image
      }
    }

    view.addSubview(closeButton)
    closeButton.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
      make.size.equalTo(40)
    }

    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
  }

  override var prefersStatusBarHidden: Bool {
    true
  }

  @objc private func closeTapped() {
    dismiss(animated: true)
  }
}

extension ImagePreviewViewController: UIScrollViewDelegate {

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
