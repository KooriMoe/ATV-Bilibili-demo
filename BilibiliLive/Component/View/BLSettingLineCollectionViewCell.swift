//
//  BLSettingLineCollectionViewCell.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/10/29.
//

import SnapKit
import UIKit

class BLSettingLineCollectionViewCell: BLMotionCollectionViewCell {
    let effectView = LiquidGlass.visualEffectView(fallback: .light)
    let selectedWhiteView = UIView()
    let titleLabel = UILabel()
    let iconImageView = UIImageView()
    private var titleLeadingConstraint: Constraint?

    var icon: UIImage? {
        didSet { updateIcon() }
    }

    override var isSelected: Bool {
        didSet {
            updateView()
        }
    }

    override func setup() {
        super.setup()
        scaleFactor = 1.05
        contentView.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.layer.cornerRadius = 30
        effectView.layer.cornerCurve = .continuous
        effectView.clipsToBounds = true
        selectedWhiteView.backgroundColor = UIColor.white
        selectedWhiteView.isHidden = !isFocused
        effectView.contentView.addSubview(selectedWhiteView)
        selectedWhiteView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true
        effectView.contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        effectView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            titleLeadingConstraint = make.leading.equalToSuperview().offset(26).constraint
            make.trailing.equalToSuperview().offset(20)
            make.top.bottom.equalToSuperview().inset(8)
        }
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 40, weight: .regular)
        updateView()
    }

    private func updateIcon() {
        iconImageView.image = icon
        let hasIcon = icon != nil
        iconImageView.isHidden = !hasIcon
        titleLeadingConstraint?.update(offset: hasIcon ? 90 : 26)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        icon = nil
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        updateView()
    }

    func updateView() {
        let highlighted = isFocused || isSelected
        selectedWhiteView.isHidden = !highlighted
        titleLabel.textColor = highlighted ? .black : .white
        titleLabel.font = UIFont.systemFont(ofSize: 40, weight: highlighted ? .semibold : .regular)
        iconImageView.tintColor = highlighted ? .black : .white
    }

    static func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(70))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.edgeSpacing = .init(leading: nil, top: .fixed(10), trailing: nil, bottom: nil)
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}
