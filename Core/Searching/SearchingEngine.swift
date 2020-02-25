//
//  SearchingEngine.swift
//  Spider
//
//  Created by jifu on 2018/11/1.
//  Copyright © 2018 Spider. All rights reserved.
//

import Foundation

enum SourceType: UInt, CaseIterable {
    case video = 0, audio = 1, soft = 2, archive = 3
    
    var extensions: Set<String> {
        switch self {
        case .video:
            return ["avi","wmv","mpeg","mp4","mov", "mkv", "flv", "f4v", "m4v", "rmvb", "rm", "3gp", "dat", "mts", "vob"]
        case .audio:
            return ["mp3","acc","aiff","amr","wav", "wv", "webm", "flac"]
        case .soft:
            return ["exe","apk","ipa"]
            
        case .archive:
            return ["zip","rar","iso","dmg","tar","tgz"]
        }
    }
    
}

// MARK: -
extension NSRegularExpression {
    static let magnetLinksExpression = try! NSRegularExpression(pattern:"(magnet:\\?xt=urn:btih:[a-z0-9]+)", options: [.caseInsensitive, .dotMatchesLineSeparators])
    static let ed2kLinksExpression = try! NSRegularExpression(pattern:"(ed2k://\\|file\\|.+?\\|\\d+?\\|\\w+?\\|/?)", options: [.caseInsensitive, .dotMatchesLineSeparators])
    static let thunderLinksExpression = try! NSRegularExpression(pattern:"(thunder://[a-z0-9+/]+=?=?)", options: [.caseInsensitive, .dotMatchesLineSeparators])
    
    //
    static let torrentKittyreSourceExpression = try! NSRegularExpression(pattern: "<td class=\"name\">(.*?)</td>.*?<td class=\"size\">(.*?)</td>.*?<a href=\"/information/(.*?)\"", options: [.caseInsensitive, .dotMatchesLineSeparators] )

    static let baiduLinksExpression = try! NSRegularExpression(pattern:"href=\"(http://www.baidu.com/link\\?url=.+?)\"", options: [.caseInsensitive, .dotMatchesLineSeparators])
    
    static func p2pLinksExpression(for types: [SourceType]) -> NSRegularExpression {
        let extensions = types.flatMap{$0.extensions}.joined(separator: "|")
        return try! NSRegularExpression(pattern:"((?:ftp|http)s?://[^\"<>]+?\\.(?:\(extensions)))", options: [.caseInsensitive, .dotMatchesLineSeparators])
    }
}

// MARK: -
protocol  SearchingEngine {
    
    var name: String {get}
    
    var shouldRetrievelinks: Bool {get}
    
    var canFetchMoreResources: Bool {get}
    
    var nextUrl: String? {get}
    
    var linksRegularExpression: NSRegularExpression? {get}
    
    var availableTypes: [SourceType] {get set}
    
    func url(for keyword: String) -> String

    func capturesResources(in str: String) -> [DownloadResource]?
    
}


// MARK: -
extension SearchingEngine {
    
    var nextUrl: String? {return nil}
    
    var linksRegularExpression: NSRegularExpression? {return nil}
    
    var shouldRetrievelinks: Bool {return false}
    
    var canFetchMoreResources: Bool {return false}
    
    func capturesResources(in str: String) -> [DownloadResource]? {
        
        var resources = [DownloadResource]()
        
        [NSRegularExpression.magnetLinksExpression,
         NSRegularExpression.ed2kLinksExpression,
         NSRegularExpression.thunderLinksExpression,
         NSRegularExpression.p2pLinksExpression(for: availableTypes)].forEach { (expression) in
            for match in expression.matches(in: str, options: [], range: NSMakeRange(0, str.count)) {
                if match.numberOfRanges == 2 {
                    let urlRange = match.range(at: 1)
                    if urlRange.length > 0 {
                        let fullstr = (str as NSString)
                        let url = fullstr.substring(with:urlRange)
                        if let res = DownloadResource(with: url)  {
                            resources.append(res)
                        }
                    }
                    
                }
            }
        }
        
        return resources
    }
    
}

// MARK: -
class Baidu: SearchingEngine {
    
    var availableTypes: [SourceType] = SourceType.allCases
    
    private var startIndex = 0
    private var keyword: String?

    var canFetchMoreResources: Bool {
        return true
    }
    
    var shouldRetrievelinks: Bool {
        return startIndex == 0
    }
    
    var nextUrl: String? {
        startIndex += 10
        guard let kw = keyword, let str = "\(kw) 迅雷下载".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return url}
        return "\(url)s?wd=\(str)&pn=\(startIndex)"
    }
    
    fileprivate(set) var name: String = "百度"
    
    private let  url: String = "http://www.baidu.com/"
    
    func url(for keyword: String) -> String {
        self.keyword = keyword
        guard let str = "\(keyword) 迅雷下载".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return url}
        return "\(url)s?wd=\(str)"
    }
    
    
    
    var linksRegularExpression: NSRegularExpression? {
        return NSRegularExpression.baiduLinksExpression
    }

}

// MARK: -
class TorrentKitty: SearchingEngine {
    
    var availableTypes: [SourceType] = SourceType.allCases
    
    private var startIndex = 1
    private var keyword: String?
    private let  url: String = "https://www.torrentkitty.app"

    var canFetchMoreResources: Bool {
        return true
    }
    
    var shouldRetrievelinks: Bool {
        return false
    }
    
    var nextUrl: String? {
        guard let kw = keyword, let str = "\(kw)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return url}
        startIndex += 1
        return "\(url)/search/\(str)/\(startIndex)"
    }
    

    fileprivate(set) var name: String = "TorrentKitty"
    
    func url(for keyword: String) -> String {
        self.keyword = keyword
        guard let str = "\(keyword)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {return url}
        return "\(url)/search/\(str)"
    }
    
    func capturesResources(in str: String) -> [DownloadResource]? {
        
        var results = [DownloadResource]()

        for match in NSRegularExpression.torrentKittyreSourceExpression.matches(in: str, options: [], range: NSMakeRange(0, str.count)) {
            if match.numberOfRanges == 4 {
                let urlRange = match.range(at: 3)
                let nameRange = match.range(at: 1)
                let sizeRange = match.range(at: 2)


                if urlRange.length > 0, nameRange.length > 0,sizeRange.length > 0 {
                    let fullstr = (str as NSString)
                    let url = fullstr.substring(with:urlRange)
                    let name = fullstr.substring(with:nameRange)
                    let size = fullstr.substring(with:sizeRange).uppercased()
                    let res = DownloadResource(url: "magnet:?xt=urn:btih:\(url)", name: name, size: size)
                    results.append(res)
                }
                
            }
        }
        
        return results
    }
}
