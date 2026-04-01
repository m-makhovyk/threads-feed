import UIKit
import Nuke

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    setupImagePipeline()
    return true
  }

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  private func setupImagePipeline() {
    let pipeline = ImagePipeline {
      $0.dataCache = try? DataCache(name: "com.makhovyk.threads-feed.images")
      $0.dataCachePolicy = .automatic
    }
    ImagePipeline.shared = pipeline
  }
}
