import Foundation

enum MockData {

  static let posts: [Post] = [
    // Five images, mixed aspect — horizontal scroll stress test.
    Post(
      author: Author(
        username: "maya.kapoor",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar9/100/100")
      ),
      text: "Five images, mixed aspect ratios — horizontal scroll test.",
      attachments: [
        picsum("j", 400, 500),
        picsum("k", 600, 400),
        picsum("l", 500, 500),
        picsum("m", 400, 700),
        picsum("n", 800, 500),
      ],
      createdAt: Date().addingTimeInterval(-36 * 3600)
    ),

    // Two images with different aspect ratios — group with real variety.
    Post(
      author: Author(
        username: "finn_walker",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar8/100/100")
      ),
      text: "Two images, mixed aspect ratios.",
      attachments: [
        picsum("h", 800, 600),
        picsum("i", 400, 700),
      ],
      createdAt: Date().addingTimeInterval(-26 * 3600)
    ),

    // No text + single portrait image — silent post case.
    Post(
      author: Author(
        username: "leo_patterson",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar3/100/100")
      ),
      text: nil,
      attachments: [
        picsum("a", 400, 500),
      ],
      createdAt: Date().addingTimeInterval(-2 * 3600)
    ),

    // No text + multiple images of mixed aspect — silent post with media group.
    Post(
      author: Author(
        username: "jordan.bishop",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar4/100/100")
      ),
      text: nil,
      attachments: [
        picsum("b", 800, 600),
        picsum("c", 400, 500),
        picsum("d", 600, 900),
      ],
      createdAt: Date().addingTimeInterval(-5 * 3600)
    ),

    // Single square image (1:1) — common Instagram-style aspect.
    Post(
      author: Author(
        username: "nikolas98",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar5/100/100")
      ),
      text: "Single square image (1080×1080).",
      attachments: [
        picsum("e", 1080, 1080),
      ],
      createdAt: Date().addingTimeInterval(-8 * 3600)
    ),

    // Single very wide panorama — exercises attachmentMinHeight clamp.
    Post(
      author: Author(
        username: "rae_s",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar6/100/100")
      ),
      text: "Single panorama (1600×600) — wide aspect, clamps to min height.",
      attachments: [
        picsum("f", 1600, 600),
      ],
      createdAt: Date().addingTimeInterval(-12 * 3600)
    ),

    // Text-only, short single line — also covers "now" date branch.
    Post(
      author: Author(
        username: "quinn.avery",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar1/100/100")
      ),
      text: "Text-only post, no attachments.",
      attachments: [],
      createdAt: Date().addingTimeInterval(-30)
    ),

    // Text-only, long multi-paragraph — tests wrapping, paragraph spacing,
    // and tall cells with no attachments below.
    Post(
      author: Author(
        username: "marco_vitti",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar2/100/100")
      ),
      text: """
      Multi-paragraph text-only post for testing line wrapping and cell height growth.

      Second paragraph after a blank line — verifies that paragraph breaks render with the expected spacing.

      Third paragraph stretches the cell further so the layout has to accommodate a tall text block with nothing below it. Useful for sanity-checking dynamic cell height when only the text contributes to it.
      """,
      attachments: [],
      createdAt: Date().addingTimeInterval(-15 * 60)
    ),

    // Long username + Cyrillic + emoji + hashtag — header truncation and
    // mixed glyph rendering.
    Post(
      author: Author(
        username: "very_long_username_for_truncation_testing_in_header",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar10/100/100")
      ),
      text: "Кирилиця + emoji 🔥 + #hashtag — font fallback and mixed glyph rendering.",
      attachments: [
        picsum("o", 400, 500),
        picsum("p", 500, 500),
      ],
      createdAt: Date().addingTimeInterval(-3 * 86400)
    ),
  ]

  private static func picsum(_ seed: String, _ width: Int, _ height: Int) -> ImageAttachment {
    ImageAttachment(
      url: URL(string: "https://picsum.photos/seed/\(seed)/\(width)/\(height)")!,
      width: width,
      height: height
    )
  }
}
