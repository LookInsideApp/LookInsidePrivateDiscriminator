import SwiftUI
import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let uiKitNavigationController = UINavigationController(rootViewController: UIKitDemoViewController())
        uiKitNavigationController.tabBarItem = UITabBarItem(
            title: "UIKit",
            image: UIImage(systemName: "rectangle.3.group"),
            selectedImage: UIImage(systemName: "rectangle.3.group.fill")
        )

        let swiftUIViewController = UIHostingController(rootView: SwiftUIDemoView())
        swiftUIViewController.title = "SwiftUI"
        let swiftUINavigationController = UINavigationController(rootViewController: swiftUIViewController)
        swiftUINavigationController.tabBarItem = UITabBarItem(
            title: "SwiftUI",
            image: UIImage(systemName: "switch.2"),
            selectedImage: UIImage(systemName: "switch.2")
        )

        viewControllers = [
            uiKitNavigationController,
            swiftUINavigationController,
        ]
    }
}
