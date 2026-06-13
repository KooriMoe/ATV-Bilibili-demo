//
//  URLPlayPlugin.swift
//  BilibiliLive
//
//  Created by yicheng on 2024/6/6.
//

import AVKit
import Foundation

class URLPlayPlugin: NSObject {
    var onPlayFail: (() -> Void)?
    var onPlayStart: (() -> Void)?

    private weak var playerVC: AVPlayerViewController?
    private let referer: String
    private let isLive: Bool
    private var currentUrl: String?

    init(referer: String = "", isLive: Bool = false) {
        self.referer = referer
        self.isLive = isLive
    }

    func play(urlString: String) {
        currentUrl = urlString
        let headers: [String: String] = [
            "User-Agent": Keys.userAgent,
            "Referer": referer,
        ]
        guard let url = URL(string: urlString) else {
            onPlayFail?()
            return
        }
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = !isLive
        playerVC?.player = player
    }
}

extension URLPlayPlugin: CommonPlayerPlugin {
    func playerDidLoad(playerVC: AVPlayerViewController) {
        self.playerVC = playerVC
        playerVC.requiresLinearPlayback = isLive
        playerVC.player = nil
        if let currentUrl {
            play(urlString: currentUrl)
        }
    }

    func playerDidStart(player: AVPlayer) {
        onPlayStart?()
    }

    func playerDidFail(player: AVPlayer) {
        onPlayFail?()
    }

    func playerDidPause(player: AVPlayer) {
        if isLive {
            onPlayFail?()
        }
    }
}
