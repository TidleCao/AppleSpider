//
//  MovieRecommend.swift
//  Spider
//
//  Created by jifu on 2018/10/30.
//  Copyright © 2018 Spider. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    
    static let recommendExpression = try! NSRegularExpression(pattern: "data-magnet=\"(magnet:\\?xt=urn:btih:[a-z|0-9]{40}.*?)\".*?<span class=\"name\".*?>(.*?)</span>.*?<span class=\"size\">(.+?)</span>", options: [.caseInsensitive, .dotMatchesLineSeparators] )

}

// MARK: -
class MovieRecommend: Spider {
    
    fileprivate(set) var name: String = "推荐资源"
    fileprivate(set) var website: String = "http://oabt007.com/index"
    fileprivate(set) var resources: [DownloadResource]?
    
    weak var delegate: SpiderDelegate?
    
    fileprivate(set) var status: SpiderStatus = .idle {
        didSet {
            switch status {
            case .sniffing:
                delegate?.spiderStartSniffing(self)
            case .fetching:
                delegate?.spiderStartFetching(self)
            case .fetched(let resources):
               delegate?.spiderFinishFetching(spider: self, discoverd: resources)
            case .abort, .fail, .success:
                delegate?.spiderFinishSniffing(self)
            default:
                break
            }
        }
    }
    
    private var startIndex = 2
    private func captures(in str: String) -> [(String, String, String)] {
        var result = [(String, String, String)]()
        
        for match in NSRegularExpression.recommendExpression.matches(in: str, options: [], range: NSMakeRange(0, str.count)) {
            if match.numberOfRanges == 4 {
                let fullstr = (str as NSString)

                let urlRange = match.range(at: 1)
                let nameRange = match.range(at: 2)
                let sizeRange = match.range(at: 3)
                let url = String(fullstr.substring(with:urlRange))
                let name = String(fullstr.substring(with: nameRange))
                let size = String(fullstr.substring(with: sizeRange))
                 result.append((url, name, size))

                
            }
        }
        return result
    }
    
    func fetchMoreResources() {
        status = .fetching
        let url = "\(website)/p/\(startIndex)"
        
        Utility.fetchWebCotent(with: url) { (err, html) in
            guard err == nil, let html = html else {
                self.status = .fail
                return
            }
            
            let magents = self.captures(in: html)
            if  magents.count > 0 {
                var newRes = [DownloadResource]()
                magents.forEach({ (url, name, size) in
                    let res = DownloadResource(url: url, name: name, size: size)
                    newRes.append(res)
                })
                self.resources?.append(contentsOf: newRes)
                self.status = .fetched(newRes)
            }
            self.startIndex += 1
        }
    }
    
    func startSniffing(_ sender: AnyObject?) {
        status = .sniffing
        Utility.fetchWebCotent(with: website) { (err, html) in
            guard err == nil, let html = html else {
                self.status = .fail
                return
            }
            
            let magents = self.captures(in: html)
            if  magents.count > 0 {
                self.resources = Array<DownloadResource>()
                magents.forEach({ (url, name, size) in
                    let res = DownloadResource(url: url, name: name, size: size)
                    self.resources?.append(res)
                })
            }
            
            self.status = .success
        }
        
    }
    
    func restartSniffing(_ sender: AnyObject?) {
        resources?.removeAll()
        startSniffing(sender)
    }
    
    func abortSinffing() {
        status = .abort
    }
}
