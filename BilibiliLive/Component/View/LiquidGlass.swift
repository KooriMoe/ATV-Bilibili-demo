//
//  LiquidGlass.swift
//  BilibiliLive
//

import UIKit

enum LiquidGlass {
    // On tvOS 26 the system substitutes the legacy material on devices that can't render Liquid Glass
    // (Apple TV HD, Apple TV 4K 1st gen), so the app doesn't need a device check — only an OS guard.
    //
    // `interactive` should be true for any glass the user can focus/press (buttons, focusable cells):
    // it opts the element into the system's press/focus reactivity (scale, bounce, directional sheen).
    static func effect(fallback: UIBlurEffect.Style, interactive: Bool = false) -> UIVisualEffect {
        if #available(tvOS 26.0, *) {
            let glass = UIGlassEffect()
            glass.isInteractive = interactive
            return glass
        }
        return UIBlurEffect(style: fallback)
    }

    static func visualEffectView(fallback: UIBlurEffect.Style, interactive: Bool = false) -> UIVisualEffectView {
        return UIVisualEffectView(effect: effect(fallback: fallback, interactive: interactive))
    }

    /// Rounds a glass/blur effect view's corners correctly on both code paths.
    ///
    /// On tvOS 26 the glass effect owns its own shape via `cornerConfiguration`; `layer.cornerRadius`
    /// is ignored for glass and `clipsToBounds = true` would hard-clip the material's edge highlight and
    /// shadow. On older OS we fall back to rounding the layer of the blur view.
    static func applyCorners(_ view: UIVisualEffectView, radius: CGFloat) {
        if #available(tvOS 26.0, *) {
            view.cornerConfiguration = .corners(radius: .fixed(Double(radius)))
        } else {
            view.layer.cornerRadius = radius
            view.layer.cornerCurve = .continuous
            view.clipsToBounds = true
        }
    }
}
