//
//  VideoDanmuFilter.swift
//  BilibiliLive
//
//  Created by yicheng on 2024/12/13.
//

import UIKit

class VideoDanmuFilter {
    static let shared = VideoDanmuFilter()

    private var stringFilters = [String]()
    private var regexFilters = [Regex<AnyRegexOutput>]()
    // accept() is called from background danmu-fetch tasks while update() may replace the arrays; guard
    // both with a lock (copy-on-read, since update() runs rarely).
    private let lock = NSLock()
    private init() {
        refreshCache(rules: VideoDanmuFilterStorage.filters)
    }

    func accept(_ danmu: String) -> Bool {
        lock.lock()
        let strings = stringFilters
        let regexes = regexFilters
        lock.unlock()
        for filter in strings {
            if danmu.contains(filter) {
                return false
            }
        }

        for filter in regexes {
            if danmu.contains(filter) {
                return false
            }
        }
        return true
    }

    func autoUpdate() {
        if Date().timeIntervalSince(VideoDanmuFilterStorage.lastUpdate) > 60 * 60 * 24 {
            Task {
                await update()
            }
        }
    }

    @discardableResult
    func update() async -> String {
        VideoDanmuFilterStorage.lastUpdate = Date()
        let data = await WebRequest.requestDanmuFilterList()
        let rules = data.rule.filter({ $0.type == 0 || $0.type == 1 })
        if !rules.isEmpty {
            VideoDanmuFilterStorage.filters = rules
            refreshCache(rules: rules)
        }
        return data.toast ?? ""
    }

    private func refreshCache(rules: [VideoDanmuFilterData.Rule]) {
        var newStrings = [String]()
        var newRegexes = [Regex<AnyRegexOutput>]()
        for filter in rules {
            switch filter.type {
            case 0:
                newStrings.append(filter.filter)
            case 1:
                if let regex = try? Regex(filter.filter) {
                    newRegexes.append(regex)
                }
            default:
                break
            }
        }
        lock.lock()
        stringFilters = newStrings
        regexFilters = newRegexes
        lock.unlock()
    }
}

private enum VideoDanmuFilterStorage {
    @UserDefaultCodable("VideoDanmuFilter.filters", defaultValue: [])
    static var filters: [VideoDanmuFilterData.Rule]

    @UserDefault("VideoDanmuFilter.lastUpdate", defaultValue: Date(timeIntervalSince1970: 0))
    static var lastUpdate: Date
}

private extension WebRequest.EndPoint {
    static let danmuFilter = "https://api.bilibili.com/x/dm/filter/user"
}

private struct VideoDanmuFilterData: Codable {
    struct Rule: Codable {
        let filter: String
        let type: Int
    }

    let rule: [Rule]
    let toast: String?
}

private extension WebRequest {
    static func requestDanmuFilterList() async -> VideoDanmuFilterData {
        do {
            let resp: VideoDanmuFilterData = try await request(url: EndPoint.danmuFilter)
            return resp
        } catch let err {
            return VideoDanmuFilterData(rule: [], toast: "\(err)")
        }
    }
}
