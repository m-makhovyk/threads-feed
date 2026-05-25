import Foundation

extension MockData {

  // Hand-tuned order to exercise edges in the mixed feed:
  //   - opens on a pure-video post (autoplay on first launch)
  //   - mixed post starting with an image (no autoplay until user swipes to a video)
  //   - mixed post starting with a video (autoplay on the first page)
  //   - mixed post with two videos back-to-back inside it (intra-post handoff)
  //   - pure-image and pure-video posts still appear
  //   - text-only post (no attachments)
  //   - long-username row at the tail (header truncation)
  static let mixedPosts: [MixedPost] = [

    // 1. Pure video, two vertical clips — opens feed on autoplay.
    MixedPost(
      author: Author(
        username: "ben_ortega",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar12/100/100")
      ),
      text: "Two vertical clips back to back.",
      attachments: [
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/S9E7vQXo9l59qs7ny/276z-17141-vrt-075-cst-0d1mtsb7qi__af1334caf1bfa1f09a983f96327932fb__P360.mp4",
          360, 640, 19
        )),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/BgrICs-NZj4hksnn3/6936a8c36eaff87ffa1ee0a4-q7houtc6tu__4da760bce69af4e79363faccd82fd5b0__P360.mp4",
          360, 640, 16
        )),
      ],
      createdAt: Date().addingTimeInterval(-18 * 3600)
    ),

    // 2. Mixed — image first, then video, then image. No autoplay until swipe.
    MixedPost(
      author: Author(
        username: "talia_morgan",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar11/100/100")
      ),
      text: "Photo, clip, photo — image-first mixed carousel.",
      attachments: [
        .image(picsum("mx1a", 600, 800)),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/rS5r4eB/12790767-xx3eijd8bf__662147cc1c670bb9da52f53027608e6e__P360.mp4",
          640, 360, 26
        )),
        .image(picsum("mx1b", 800, 600)),
      ],
      createdAt: Date().addingTimeInterval(-12 * 3600)
    ),

    // 3. Pure image, five-image horizontal scroll.
    MixedPost(
      author: Author(
        username: "maya.kapoor",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar9/100/100")
      ),
      text: "Five images, mixed aspect ratios — horizontal scroll test.",
      attachments: [
        .image(picsum("j", 400, 500)),
        .image(picsum("k", 600, 400)),
        .image(picsum("l", 500, 500)),
        .image(picsum("m", 400, 700)),
        .image(picsum("n", 800, 500)),
      ],
      createdAt: Date().addingTimeInterval(-36 * 3600)
    ),

    // 4. Mixed — video first, then image. Autoplay on the first page.
    MixedPost(
      author: Author(
        username: "zoe.nakamura",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar13/100/100")
      ),
      text: "Clip then a still — video-first mixed carousel.",
      attachments: [
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/GTYSdDW/large-plane-landing_-jjf8lfeh__b476c5a67b30e795a3977b238e867fe0__P360.mp4",
          854, 360, 14
        )),
        .image(picsum("mx2", 1080, 1080)),
      ],
      createdAt: Date().addingTimeInterval(-9 * 3600)
    ),

    // 5. Mixed — two videos back-to-back inside the post, then an image.
    //    Tests intra-post handoff: swiping V→V should keep playback continuous.
    MixedPost(
      author: Author(
        username: "harper_reed",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar14/100/100")
      ),
      text: nil,
      attachments: [
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/ByZVUTp1Gja5fwdxr/videoblocks-back-view-of-senior-couple-running-upstairs-in-the-park-enjoying-carefree-life-on-sunny-day_rprznqpscv__f4a6d6ed63e5915d5c58f8d8efc6f99b__P360.mp4",
          640, 360, 9
        )),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/rS5r4eB/12790737-qh9g67ys6e__beab4d542f945db5faa8c52e817fb584__P360.mp4",
          360, 640, 23
        )),
        .image(picsum("mx3", 400, 500)),
      ],
      createdAt: Date().addingTimeInterval(-6 * 3600)
    ),

    // 6. Pure image, single portrait, no text — silent post.
    MixedPost(
      author: Author(
        username: "leo_patterson",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar3/100/100")
      ),
      text: nil,
      attachments: [
        .image(picsum("a", 400, 500)),
      ],
      createdAt: Date().addingTimeInterval(-2 * 3600)
    ),

    // 7. Mixed — minimal 2-page mix: image, video.
    MixedPost(
      author: Author(
        username: "finn_walker",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar8/100/100")
      ),
      text: "Two-page mix — one photo, one clip.",
      attachments: [
        .image(picsum("mx4", 800, 600)),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/rS5r4eB/5831881-6eklcq873k__7aee18482487e91d95a523c14d884a67__P360.mp4",
          640, 360, 30
        )),
      ],
      createdAt: Date().addingTimeInterval(-1 * 3600)
    ),

    // 8. Text-only post, no attachments.
    MixedPost(
      author: Author(
        username: "quinn.avery",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar1/100/100")
      ),
      text: "Text-only post, no attachments.",
      attachments: [],
      createdAt: Date().addingTimeInterval(-30)
    ),

    // 9. Mixed — long carousel: image, image, video, image, video.
    MixedPost(
      author: Author(
        username: "jordan.bishop",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar4/100/100")
      ),
      text: "Long mixed carousel — five pages, two videos sprinkled in.",
      attachments: [
        .image(picsum("mx5a", 800, 600)),
        .image(picsum("mx5b", 600, 800)),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/S9E7vQXo9l59qs7ny/276z-17141-vrt-075-cst-0d1mtsb7qi__af1334caf1bfa1f09a983f96327932fb__P360.mp4",
          360, 640, 19
        )),
        .image(picsum("mx5c", 1080, 1080)),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/BgrICs-NZj4hksnn3/6936a8c36eaff87ffa1ee0a4-q7houtc6tu__4da760bce69af4e79363faccd82fd5b0__P360.mp4",
          360, 640, 16
        )),
      ],
      createdAt: Date().addingTimeInterval(-3 * 3600)
    ),

    // 10. Long username + Cyrillic + emoji + mixed (image, video).
    MixedPost(
      author: Author(
        username: "very_long_username_for_truncation_testing_in_header",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar10/100/100")
      ),
      text: "Кирилиця + emoji 🔥 + #hashtag — long username with a mixed carousel.",
      attachments: [
        .image(picsum("o", 400, 500)),
        .video(video(
          "https://d2j2uxe7jasn0r.cloudfront.net/watermarks/video/SyxJXpREipgtq2dd/videoblocks-cinematic-inspiring-shot-of-young-woman-run-down-epic-boardwalk-down-to-rocky-ocean-coastline-female-adventurer-explore-sunset-coast-scenic-vacation-travel-destination-wanderlust-lifestyle_bsijjomr___8d6893fabd18f733a99f085d17b323ce__P360.mp4",
          640, 360, 32
        )),
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
