//
//  UIViewController+Ext.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/8/20.
//

import UIKit

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }

        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }

        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }

        return self
    }

    static func topMostViewController() -> UIViewController? {
        // `window` resolves through the active scene and can be nil before a scene connects or after it
        // disconnects (e.g. DLNA casting events fired by the always-on UPnP server at launch / in the
        // background). Return nil instead of force-unwrapping so callers can no-op gracefully.
        let root = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
            ?? AppDelegate.shared.window?.rootViewController
        return root?.topMostViewController()
    }
}
