//
//  Spider.swift
//  Spider
//
//  Created by jifu on 2018/10/24.
//  Copyright © 2018 Spider. All rights reserved.
//

import Foundation

enum ResourceScheme: String {
    case magnet, ed2k, thunder, http, https, ftp, ftps
}

//MARK: -
struct DownloadResource{
    var url: String
    var name: String
    var size: String?
    
    init(url: String, name: String, size: String?) {
        self.url = url
        self.name = name
        self.size = size
    }
    
    init?(with url: String){
        self.url = url
        if let (name, size) = Utility.retrieveNameAndSize(from: url) {
            self.name = name
            self.size = size
        }else {
            name = "\(Utility.urlScheme(for: url)?.rawValue ?? "") - \(url))"
        }
    }
    
    var description: String {
        return "name:\(name), url: \(url), size: \(size ?? "0B")"
    }
    
}

// MARK: -
protocol SpiderDelegate: class {
    
    func spiderStartSniffing(_ spider: Spider)
    func spiderFinishSniffing(_ spider: Spider)
    
    func spiderStartFetching(_ spider: Spider)
    func spiderFinishFetching(spider: Spider, discoverd resources: [DownloadResource])
}

// MARK: -
enum SpiderStatus {
    // idle -> sniffing -> success -/-/-> fetching -> [success, fail, abort]
    case idle, sniffing, fetching, fetched([DownloadResource]), success, fail, abort
}

// MARK: -
protocol Spider {

    var name: String {get}
    var status: SpiderStatus {get}
    var resources: [DownloadResource]? {get}
    var delegate: SpiderDelegate? {get set}

    func restartSniffing(_ sender: AnyObject?)
    func startSniffing(_ sender: AnyObject?)
    func abortSinffing()
    func fetchMoreResources()
}

// MARK: -
extension Spider {
    func abortSinffing() {}
    func restartSniffing(_ sender: AnyObject?) {}
    func fetchMoreResources(){}
}

