import UIKit

class TabBarController: UITabBarController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let imageFeed = ImageFeedViewController()
    imageFeed.tabBarItem = UITabBarItem(
      title: "Images",
      image: UIImage(systemName: "photo"),
      selectedImage: UIImage(systemName: "photo.fill")
    )

    let videoFeed = VideoFeedViewController()
    videoFeed.tabBarItem = UITabBarItem(
      title: "Videos",
      image: UIImage(systemName: "video"),
      selectedImage: UIImage(systemName: "video.fill")
    )

    viewControllers = [imageFeed, videoFeed]
  }
}
