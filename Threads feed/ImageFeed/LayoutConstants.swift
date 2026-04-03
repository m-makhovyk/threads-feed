import Foundation

enum LayoutConstants {

  static let avatarSize: CGFloat = 40
  static let avatarCornerRadius: CGFloat = avatarSize / 2
  static let avatarToContentSpacing: CGFloat = 10

  /// Leading edge where post content (text, media) begins
  static let contentLeadingInset: CGFloat = 16 + avatarSize + avatarToContentSpacing

  static let attachmentHeight: CGFloat = 350
  static let attachmentCornerRadius: CGFloat = 12
  static let attachmentImageWidth: CGFloat = 280
  static let attachmentImageSpacing: CGFloat = 8
}
