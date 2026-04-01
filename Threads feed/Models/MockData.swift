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
        URL(string: "https://picsum.photos/seed/mountain1/800/600")!,
        URL(string: "https://picsum.photos/seed/mountain2/400/500")!,
        URL(string: "https://picsum.photos/seed/mountain3/600/900")!,
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
        URL(string: "https://picsum.photos/seed/food1/400/500")!,
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
        URL(string: "https://picsum.photos/seed/city1/400/500")!,
        URL(string: "https://picsum.photos/seed/city2/400/500")!,
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
        URL(string: "https://picsum.photos/seed/cat1/300/300")!,
        URL(string: "https://picsum.photos/seed/cat2/500/800")!,
        URL(string: "https://picsum.photos/seed/cat3/900/400")!,
        URL(string: "https://picsum.photos/seed/cat4/400/500")!,
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
        URL(string: "https://picsum.photos/seed/dog1/400/500")!,
        URL(string: "https://picsum.photos/seed/dog2/400/500")!,
      ],
      createdAt: Date().addingTimeInterval(-19 * 3600)
    ),
  ]
}
