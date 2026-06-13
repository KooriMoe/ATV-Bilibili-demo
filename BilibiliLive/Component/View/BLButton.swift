//
//  BLButton.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/10/22.
//

import SnapKit
import TVUIKit

@IBDesignable
@MainActor
class BLCustomButton: BLButton {
    @IBInspectable var image: UIImage? {
        didSet { updateButton() }
    }

    @IBInspectable var onImage: UIImage? {
        didSet { updateButton() }
    }

    @IBInspectable var highLightImage: UIImage? {
        didSet { updateButton() }
    }

    @IBInspectable var title: String? {
        didSet {
            updateTitleLabel()
        }
    }

    @IBInspectable var titleColor: UIColor = UIColor.black.withAlphaComponent(0.9) {
        didSet { titleLabel.textColor = titleColor }
    }

    @IBInspectable var titleFont: UIFont = .systemFont(ofSize: 24) {
        didSet { titleLabel.font = titleFont }
    }

    var isOn: Bool = false {
        didSet {
            updateButton()
        }
    }

    private let titleLabel = UILabel()
    private let imageView = UIImageView()

    override func setup() {
        super.setup()
        // Icon chip: keep a rounded-rect, not the base capsule (effectView is only the square icon area
        // with the title laid out below it, so height / 2 would over-round it).
        effectCornerRadius = 8
        if #available(tvOS 26.0, *) {
            effectView.cornerConfiguration = .corners(radius: .fixed(8))
        }
        titleLabel.isUserInteractionEnabled = false
        effectView.contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(imageView.snp.width)
        }
        imageView.image = image
        addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        updateTitleLabel(force: true)
    }

    private func updateTitleLabel(force: Bool = false) {
        let shouldHide = title == nil || title?.count == 0
        titleLabel.text = title
        if force || titleLabel.isHidden != shouldHide {
            titleLabel.isHidden = shouldHide
            if shouldHide {
                titleLabel.snp.removeConstraints()
            } else {
                titleLabel.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(effectView.snp.bottom).offset(10)
                }
            }
        }
    }

    private func getImage() -> UIImage? {
        isOn ? onImage : image
    }

    private func updateButton() {
        if isFocused {
            imageView.image = highLightImage ?? getImage()
            imageView.tintColor = .black
        } else {
            imageView.image = getImage()
            imageView.tintColor = .white
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        updateButton()
    }
}

@IBDesignable
@MainActor
class BLCustomTextButton: BLButton {
    private let titleLabel = UILabel()
    var object: Any?

    @IBInspectable var title: String? {
        didSet { titleLabel.text = title }
    }

    @IBInspectable var titleColor: UIColor = .white {
        didSet { titleLabel.textColor = titleColor }
    }

    @IBInspectable var titleSelectedColor: UIColor = .black {
        didSet { titleLabel.textColor = titleColor }
    }

    @IBInspectable var titleFont: UIFont = .systemFont(ofSize: 28) {
        didSet { titleLabel.font = titleFont }
    }

    override func setup() {
        super.setup()
        effectView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.left.right.equalToSuperview().inset(24)
        }
        titleLabel.text = title
        titleLabel.font = titleFont
        titleLabel.textColor = isFocused ? titleSelectedColor : titleColor
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        titleLabel.textColor = isFocused ? titleSelectedColor : titleColor
    }
}

class BLButton: UIControl {
    private var motionEffect: UIInterpolatingMotionEffect!
    fileprivate let effectView = LiquidGlass.visualEffectView(fallback: .dark, interactive: true)
    private let selectedWhiteView = UIView()

    /// Fixed corner radius for the glass/blur background. `nil` renders a capsule (height / 2).
    /// Subclasses set this in `setup()` after `super.setup()`.
    fileprivate var effectCornerRadius: CGFloat?

    var onPrimaryAction: ((BLButton) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var canBecomeFocused: Bool { return true }

    func setup() {
        isUserInteractionEnabled = true
        motionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        motionEffect.maximumRelativeValue = 8
        motionEffect.minimumRelativeValue = -8
        selectedWhiteView.isHidden = !isFocused
        addSubview(effectView)
        effectView.isUserInteractionEnabled = false
        if #available(tvOS 26.0, *) {
            // Glass owns its shape; default to a capsule (subclasses override in their setup()).
            effectView.cornerConfiguration = .capsule()
        } else {
            effectView.layer.cornerCurve = .continuous
            effectView.clipsToBounds = true
        }
        effectView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().priority(.high)
        }
        effectView.contentView.addSubview(selectedWhiteView)
        selectedWhiteView.backgroundColor = UIColor.white
        // The white focus fill sits on the glass/blur. On the glass path the effect view isn't clipped
        // (clipping would cut its edge highlight/shadow), so the fill must round itself to stay inside.
        selectedWhiteView.layer.cornerCurve = .continuous
        selectedWhiteView.clipsToBounds = true
        selectedWhiteView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = effectCornerRadius ?? (effectView.bounds.height / 2)
        selectedWhiteView.layer.cornerRadius = radius
        // The glass shape is set once via cornerConfiguration (layer.cornerRadius is ignored for glass);
        // only the legacy blur path needs the radius recomputed here as the height changes.
        if #available(tvOS 26.0, *) { return }
        effectView.layer.cornerRadius = radius
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        if presses.first?.type == .select {
            sendActions(for: .primaryActionTriggered)
            onPrimaryAction?(self)
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if isFocused {
            selectedWhiteView.isHidden = false
            coordinator.addCoordinatedAnimations {
                self.transform = CGAffineTransformMakeScale(1.1, 1.1)
                let scaleDiff = (self.bounds.size.height * 1.1 - self.bounds.size.height) / 2
                self.transform = CGAffineTransformTranslate(self.transform, 0, -scaleDiff)
                self.layer.shadowOffset = CGSizeMake(0, 10)
                self.layer.shadowOpacity = 0.15
                self.layer.shadowRadius = 16.0
                self.addMotionEffect(self.motionEffect)
            }
        } else {
            selectedWhiteView.isHidden = true
            coordinator.addCoordinatedAnimations {
                self.transform = CGAffineTransformIdentity
                self.layer.shadowOpacity = 0
                self.layer.shadowOffset = CGSizeMake(0, 0)
                self.removeMotionEffect(self.motionEffect)
            }
        }
    }
}
