//
//  ResourceSeaching.swift
//  Spider
//
//  Created by jifu on 2018/10/29.
//  Copyright © 2018 Spider. All rights reserved.
//

import Cocoa

// MARK: -
class ResourceSeaching: NSViewController, Spider {
    private let engines: [SearchingEngine] = {
        return [Baidu(), TorrentKitty()]
    }()
    weak var delegate: SpiderDelegate?
    
    private var currentSearchingEngine: SearchingEngine!
    
    fileprivate(set) var name: String = "全网搜"
    fileprivate(set) var resources: [DownloadResource]?
    
    @IBOutlet weak var searchingBtn: NSButton!
    @IBOutlet weak var resourceTypeSelectionMatrix: NSMatrix!
    
    @IBOutlet weak var searchingEnginePopupBtn: NSPopUpButton! {
        didSet {
            searchingEnginePopupBtn.removeAllItems()
            engines.forEach { (egine) in
                searchingEnginePopupBtn.addItem(withTitle: egine.name)
            }
            currentSearchingEngine = engines[0]
        }
    }
    
    @IBOutlet weak var searchingTextField: NSTextField! {
        didSet {
            searchingTextField.delegate = self
        }
    }
    
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
    
    init() {
        super.init(nibName: "ResourceSeaching", bundle: Bundle(for: type(of:self)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func retrieveAvailableLinks(from rawHtml: String) -> [String] {
        guard let linksRegularExpression =  currentSearchingEngine.linksRegularExpression else {
            return [String]()
        }
        
        var results = [String]()
        
        for match in linksRegularExpression.matches(in: rawHtml, options: [], range: NSMakeRange(0, rawHtml.count)) {
            if match.numberOfRanges == 2 {
                let urlRange = match.range(at: 1)
                if urlRange.length > 0 {
                    let fullstr = (rawHtml as NSString)
                    let url = fullstr.substring(with:urlRange)
                    results.append(url)
                }
                
            }
        }
        return results
        
    }
    
    private func search(in url: String, isFetching: Bool) {
        status = isFetching ? .fetching : .sniffing
        Utility.fetchWebCotent(with: url) { (err, html) in
            if err == nil, let html = html {
                if self.currentSearchingEngine.shouldRetrievelinks {
                    let links = self.retrieveAvailableLinks(from: html)
                    if links.count > 0 {
                        links.forEach({ (link) in
                            Utility.fetchWebCotent(with: link, handler: { (e, webContent) in
                                if e == nil, let content = webContent {
                                    if let resources = self.currentSearchingEngine.capturesResources(in: content), resources.count > 0 {
                                        self.resources?.append(contentsOf: resources)
                                        self.status = SpiderStatus.fetched(resources)
                                        DebugLog("sniffed resources:\(resources)")
                                    }
                                }
                            })
                        })
                    }else{
                        self.status = .fail
                    }
                } else {
                    
                    if let res = self.currentSearchingEngine.capturesResources(in: html) {
                        DebugLog("captured resources:\(res)")
                        self.resources?.append(contentsOf: res)
                        if isFetching {
                            self.status = SpiderStatus.fetched(res)
                        }else{
                            self.status = .success
                        }
                    }else {
                        self.status = .fail
                    }
                }
                
                
            }else{
                self.status = .fail
            }
        }
    }
    
    private func search(with keyword: String) {
        let url = currentSearchingEngine.url(for: keyword)
        resources?.removeAll()
        resources = [DownloadResource]()
        search(in: url, isFetching: false)
    }
    
    @IBAction func onSearchingEngineChanged(_ sender: NSPopUpButton) {
        let es = engines.filter{$0.name == sender.title}
        if es.count > 0 {
            currentSearchingEngine = es[0]
        }
    }
    
    @IBAction func searchWithKeywords(_ sender: Any) {
        
        let types =  resourceTypeSelectionMatrix.cells.filter{$0.state == NSControl.StateValue.on}.map { SourceType(rawValue: UInt($0.tag)) ?? SourceType.video}
        currentSearchingEngine.availableTypes = types
        let keyword = searchingTextField.stringValue
        search(with: keyword)
        dismiss(self)
    }
    
    @IBAction func onSourceTypeSelectionChanged(_ sender: NSMatrix) {
        
        searchingBtn.isEnabled = sender.cells.filter{$0.state == .on}.count > 0
    }
    
    @IBAction func cancel(_ sender: Any?) {
        abortSinffing()
        dismiss(self)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        searchingBtn.isEnabled = searchingTextField.stringValue.count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func startSniffing(_ sender: AnyObject?) {
        guard let vc = sender as? NSViewController else { return }
        vc.presentAsSheet(self)
    }
    
    func restartSniffing(_ sender: AnyObject?) {
        status =  .idle
        startSniffing(sender)
    }
    
    func abortSinffing() {
        status = .abort
    }
    
    func fetchMoreResources() {
        guard currentSearchingEngine.canFetchMoreResources, let url = currentSearchingEngine.nextUrl else {return}
        DebugLog("fetching more resources for url: \(url)")
        search(in: url, isFetching: true)
    }
}

// MARK: -
extension ResourceSeaching: NSTextFieldDelegate {
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        guard let tf = obj.object as? NSTextField, tf == searchingTextField else {return}
        status = .idle
    }
    
    func controlTextDidChange(_ obj: Notification) {
        guard let tf = obj.object as? NSTextField, tf == searchingTextField else {return}
        
        let isTypeSelected = resourceTypeSelectionMatrix.cells.filter{$0.state == .on}.count > 0
        
        searchingBtn.isEnabled =  isTypeSelected && tf.stringValue.count > 0
    }
    
}

