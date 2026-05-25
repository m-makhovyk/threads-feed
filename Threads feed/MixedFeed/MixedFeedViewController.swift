import UIKit
import SnapKit

class MixedFeedViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    let label = UILabel()
    label.text = "Mixed"
    label.font = .preferredFont(forTextStyle: .largeTitle)
    label.textColor = .secondaryLabel
    view.addSubview(label)
    label.snp.makeConstraints { make in
      make.center.equalToSuperview()
    }
  }
}
