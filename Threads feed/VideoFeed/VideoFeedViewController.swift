import UIKit
import SnapKit

class VideoFeedViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let label = UILabel()
    label.text = "Video Feed"
    label.font = .systemFont(ofSize: 24, weight: .bold)
    view.addSubview(label)

    label.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
}
