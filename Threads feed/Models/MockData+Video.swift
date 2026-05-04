import Foundation

extension MockData {

  static let videoPosts: [VideoPost] = [
    // Three clips, mixed orientations — horizontal scroll stress test.
    VideoPost(
      author: Author(
        username: "talia_morgan",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar11/100/100")
      ),
      text: "Three clips, mixed orientations — horizontal scroll test.",
      attachments: [
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/rS5r4eB/12790767-xx3eijd8bf__662147cc1c670bb9da52f53027608e6e__P360.mp4",
          640, 360, 26
        ),
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/rS5r4eB/12790737-qh9g67ys6e__beab4d542f945db5faa8c52e817fb584__P360.mp4",
          360, 640, 23
        ),
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/rS5r4eB/5831881-6eklcq873k__7aee18482487e91d95a523c14d884a67__P360.mp4",
          640, 360, 30
        ),
      ],
      createdAt: Date().addingTimeInterval(-42 * 3600)
    ),

    // Two vertical clips — same-orientation carousel.
    VideoPost(
      author: Author(
        username: "ben_ortega",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar12/100/100")
      ),
      text: "Two vertical clips back to back.",
      attachments: [
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/S9E7vQXo9l59qs7ny/276z-17141-vrt-075-cst-0d1mtsb7qi__af1334caf1bfa1f09a983f96327932fb__P360.mp4",
          360, 640, 19
        ),
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/BgrICs-NZj4hksnn3/6936a8c36eaff87ffa1ee0a4-q7houtc6tu__4da760bce69af4e79363faccd82fd5b0__P360.mp4",
          360, 640, 16
        ),
      ],
      createdAt: Date().addingTimeInterval(-18 * 3600)
    ),

    // Single very wide cinematic clip — exercises wide-aspect clamp.
    VideoPost(
      author: Author(
        username: "zoe.nakamura",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar13/100/100")
      ),
      text: "Single cinematic 2.37:1 clip — wide aspect, clamps to min height.",
      attachments: [
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/GTYSdDW/large-plane-landing_-jjf8lfeh__b476c5a67b30e795a3977b238e867fe0__P360.mp4",
          854, 360, 14
        ),
      ],
      createdAt: Date().addingTimeInterval(-7 * 3600)
    ),

    // Short single wide clip with no text — silent video post.
    VideoPost(
      author: Author(
        username: "harper_reed",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar14/100/100")
      ),
      text: nil,
      attachments: [
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/ByZVUTp1Gja5fwdxr/videoblocks-back-view-of-senior-couple-running-upstairs-in-the-park-enjoying-carefree-life-on-sunny-day_rprznqpscv__f4a6d6ed63e5915d5c58f8d8efc6f99b__P360.mp4",
          640, 360, 9
        ),
      ],
      createdAt: Date().addingTimeInterval(-90)
    ),

    // Long username + Cyrillic + emoji + hashtag — header truncation and
    // mixed glyph rendering, single wide clip.
    VideoPost(
      author: Author(
        username: "very_long_video_creator_username_for_header_truncation_testing",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar15/100/100")
      ),
      text: "Кирилиця + emoji 🎬 + #wanderlust — font fallback over a video clip.",
      attachments: [
        video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/SyxJXpREipgtq2dd/videoblocks-cinematic-inspiring-shot-of-young-woman-run-down-epic-boardwalk-down-to-rocky-ocean-coastline-female-adventurer-explore-sunset-coast-scenic-vacation-travel-destination-wanderlust-lifestyle_bsijjomr___8d6893fabd18f733a99f085d17b323ce__P360.mp4",
          640, 360, 32
        ),
      ],
      createdAt: Date().addingTimeInterval(-2 * 86400)
    ),
  ]

  private static func video(
    _ urlString: String,
    _ width: Int,
    _ height: Int,
    _ duration: TimeInterval
  ) -> VideoAttachment {
    VideoAttachment(
      url: URL(string: urlString)!,
      width: width,
      height: height,
      duration: duration
    )
  }
}
