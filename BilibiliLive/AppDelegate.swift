//
//  AppDelegate.swift
//  BilibiliLive
//
//  Created by Etan on 2021/3/27.
//

import AVFoundation
import CocoaLumberjackSwift
import Kingfisher
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.delegate as? SceneDelegate }
            .first?.window
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Logger.setup()
        ImageCache.default.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        AVInfoPanelCollectionViewThumbnailCellHook.start()
        AccountManager.shared.bootstrap()
        BiliBiliUpnpDMR.shared.start()
        URLSession.shared.configuration.headers.add(.userAgent("BiLiBiLi AppleTV Client/1.0.0 (github/yichengchen/ATV-Bilibili-live-demo)"))
        WebRequest.requestIndex()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func showLogin() {
        replaceRootViewController(with: LoginViewController.create(), animated: false)
    }

    func showTabBar() {
        replaceRootViewController(with: BLTabBarViewController(), animated: false)
    }

    func resetTabBar() {
        replaceRootViewController(with: BLTabBarViewController(), animated: true)
    }

    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    private func replaceRootViewController(with viewController: UIViewController, animated: Bool) {
        guard let window else { return }
        if animated, let snapshot = window.snapshotView(afterScreenUpdates: false) {
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            viewController.view.addSubview(snapshot)
            UIView.animate(withDuration: 0.25, animations: {
                snapshot.alpha = 0
            }, completion: { _ in
                snapshot.removeFromSuperview()
            })
        } else {
            window.rootViewController = viewController
            window.makeKeyAndVisible()
        }
    }
}
