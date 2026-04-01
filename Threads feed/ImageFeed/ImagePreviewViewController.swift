import UIKit
import SnapKit
import Nuke

class ImagePreviewViewController: UIViewController {

  private let imageURL: URL
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

    imageView.contentMode = .scaleAspectFit
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    imageView.frame = view.bounds
    ImagePipeline.shared.loadImage(with: imageURL) { [weak self] result in
      if case .success(let response) = result {
        self?.imageView.image = response.image
      }
    }
    view.addSubview(imageView)

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
