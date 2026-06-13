//
//  LiquidGlass.swift
//  BilibiliLive
//

import UIKit

enum LiquidGlass {
    // On tvOS 26 the system substitutes the legacy material on devices that can't render Liquid Glass
    // (Apple TV HD, Apple TV 4K 1st gen), so the app doesn't need a device check — only an OS guard.
    static func effect(fallback: UIBlurEffect.Style) -> UIVisualEffect {
        if #available(tvOS 26.0, *) {
            return UIGlassEffect()
        }
        return UIBlurEffect(style: fallback)
    }

    static func visualEffectView(fallback: UIBlurEffect.Style) -> UIVisualEffectView {
        return UIVisualEffectView(effect: effect(fallback: fallback))
    }

    static func upgrade(_ view: UIVisualEffectView) {
        if #available(tvOS 26.0, *) {
            view.effect = UIGlassEffect()
        }
    }
}
