import Foundation

enum MockData {

  static let posts: [Post] = [
    Post(
      author: Author(
        username: "travel.adventures",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar2/100/100")
      ),
      text: "Morning hike in the mountains. The view was absolutely worth waking up at 5am",
      attachments: [
        picsum("mountain1", 800, 600),
        picsum("mountain2", 400, 500),
        picsum("mountain3", 600, 900),
      ],
      createdAt: Date().addingTimeInterval(-5 * 3600)
    ),
    Post(
      author: Author(
        username: "foodie.ua",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar3/100/100")
      ),
      text: nil,
      attachments: [
        picsum("food1", 400, 500),
      ],
      createdAt: Date().addingTimeInterval(-2 * 3600)
    ),
    Post(
      author: Author(
        username: "dev.thoughts",
        avatarURL: URL(string: "https://picsum.photos/seed/devavatar/100/100")
      ),
      text: "Hot take: the best code is the code you didn't write. Deleted 2000 lines today and everything still works. Might be the most productive day this year",
      attachments: [],
      createdAt: Date().addingTimeInterval(-8 * 3600)
    ),
    Post(
      author: Author(
        username: "street.photo",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar4/100/100")
      ),
      text: "City lights at night. No filter needed when the city does the work for you",
      attachments: [
        picsum("city1", 400, 500),
        picsum("city2", 400, 500),
      ],
      createdAt: Date().addingTimeInterval(-12 * 3600)
    ),
    Post(
      author: Author(
        username: "cat.lover.99",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar5/100/100")
      ),
      text: "She finally learned how to open doors. We're doomed",
      attachments: [
        picsum("cat1", 300, 300),
        picsum("cat2", 500, 800),
        picsum("cat3", 900, 400),
        picsum("cat4", 400, 500),
      ],
      createdAt: Date().addingTimeInterval(-36 * 3600)
    ),
    Post(
      author: Author(
        username: "lazy.paws",
        avatarURL: URL(string: "https://picsum.photos/seed/avatar1/100/100")
      ),
      text: "Just a regular rectangular dog, nothing to see here",
      attachments: [
        picsum("dog1", 400, 500),
        picsum("dog2", 400, 500),
      ],
      createdAt: Date().addingTimeInterval(-19 * 3600)
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
