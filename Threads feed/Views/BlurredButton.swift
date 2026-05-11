import UIKit

final class BlurredButton: UIButton {

  private let diameter: CGFloat

  init(
    systemName: String,
    diameter: CGFloat = 40,
    pointSize: CGFloat = 15,
    weight: UIImage.SymbolWeight = .semibold,
    blurStyle: UIBlurEffect.Style = .systemThinMaterialDark
  ) {
    self.diameter = diameter
    super.init(frame: .zero)

    var config = UIButton.Configuration.plain()
    config.image = UIImage(
      systemName: systemName,
      withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    )
    config.baseForegroundColor = .white
    config.contentInsets = .zero
    config.background.visualEffect = UIBlurEffect(style: blurStyle)
    config.background.cornerRadius = diameter / 2
    configuration = config
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: diameter, height: diameter)
  }
}
