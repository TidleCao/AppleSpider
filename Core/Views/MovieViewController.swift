//
//  MovieViewController.swift
//  Spider
//
//  Created by jifu on 2018/10/24.
//  Copyright © 2018 Spider. All rights reserved.
//

import Cocoa

extension NSUserInterfaceItemIdentifier {
    
    static let movieTableCellView = NSUserInterfaceItemIdentifier(rawValue: "movieTableCellView")
    
}

enum SortType: Int, CaseIterable {

    case date, size, name
    
    var description: String {
        switch self {
        case .date:
            return "按时间"
        case .size:
            return "按大小"
        case .name:
            return "按名称"
        }
    }
}

// MARK: -
class Movie: NSObject {
    
    @objc dynamic var isSelected: Bool = false

    var downloadResouce: DownloadResource?
    
    init(with resource: DownloadResource, selection: Bool = false) {
        self.downloadResouce = resource
        self.isSelected = selection
    }
    
    func download() {
        guard let link = downloadResouce?.url else {return}
        guard let scheme = Utility.urlScheme(for: link) else {return}
        
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.xunlei.Thunder").first == nil {
            var str = link
            switch scheme {
            case .thunder, .magnet:
                break
            default:
                str = Utility.encodeThunder(string: str) ?? str
            }
            guard  let url = URL(string: str) else { return }
            NSWorkspace.shared.open(url)
        } else {
            postNewTasks([link], configuration: nil)
        }

    }
    
    @objc func postNewTasks(_ tasks: [String], configuration: [String: Any]?) {
        
        var userInfo = [String: Any]()
        
        var allTasks = [[String: Any]]()
        for url in tasks {
            let taskInfo: [String: Any] = ["url": url]

            allTasks.append(taskInfo)
        }
        
        userInfo["tasks"] = allTasks
        
        self.post((Notification.Name("CTNewTask"),
                   userInfo))
        
    }
    
    typealias HelperMessage = (name: Notification.Name, userInfo: [String: Any]?)

    private func post(_ message: HelperMessage) {
        
        DistributedNotificationCenter.default().postNotificationName(message.name,
                                                           object: "com.xunlei.Thunder.CreateTaskObject",
                                                           userInfo: message.userInfo,
                                                           deliverImmediately: true)
        
    }
    
    
}



// MARK: -
class MovieViewController: NSViewController {
    
    @objc dynamic var resourcesAvailable: Bool = false
    @objc dynamic var resourcesDownloadable: Bool = false
    @objc dynamic var isSniffing: Bool = true {
        didSet {
            if isSniffing {
                indicator?.startAnimation(nil)
                searchBtn?.image = NSImage(named: NSImage.stopProgressFreestandingTemplateName)
                
            }else {
                indicator?.stopAnimation(nil)
                searchBtn?.image = NSImage(named: NSImage.refreshFreestandingTemplateName)

            }
        }
    }
    
    @objc dynamic var sortSelectedIndex: Int = 0

    fileprivate(set) var contents = [Movie]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    lazy var spiders: [Spider] = {
        let recommend = MovieRecommend()
        let resSearch = ResourceSeaching()
        recommend.delegate = self
        resSearch.delegate = self

        return [recommend, resSearch]
    }()

    var currentSpider: Spider? {
        didSet {
            contents.removeAll()
            
            if currentSpider?.resources == nil {
                currentSpider?.startSniffing(self)
            } else {
                if let res = currentSpider?.resources {
                    contents = res.compactMap({ (d) -> Movie in
                        return Movie(with: d, selection: false)
                    })
                }
            }
            
            DispatchQueue.main.async {
                self.onContentsCountChanged()
            }

        }
    }
    
    @IBOutlet weak var searchBtn: NSButton!
    @IBOutlet weak var promptLabel: NSTextField!
    
    @IBOutlet weak var countLabel: NSTextField!
    
    @IBOutlet weak var indicator: NSProgressIndicator!
    
    @IBOutlet weak var tableView: NSTableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            if let scrollview = tableView.enclosingScrollView as? RefreshableScrollView {
                scrollview.delegate = self
            }
        }
    }
    
    @IBOutlet weak var sortPopupButton: NSPopUpButton! {
        didSet {
            sortPopupButton.removeAllItems()
            sortPopupButton.addItems(withTitles: SortType.allCases.map{$0.description})
        }
    }
    
    
    @IBOutlet weak var popupBtn: NSPopUpButton! {
        didSet {
            popupBtn.removeAllItems()
            spiders.forEach { (spider) in
                popupBtn.addItem(withTitle: spider.name)
            }
        }
    }
    
    @IBAction func handleSwitchSpiderAction(_ sender: NSPopUpButton) {
        guard sender.selectedItem?.title != currentSpider?.name else {return}
        for spider in spiders {
            if spider.name == sender.selectedItem?.title {
                currentSpider = spider
            }
        }
    }
    
    @IBAction func toggleAllSelection(_ sender: NSButton) {
        
        contents.forEach({ (movie) in
            movie.isSelected = sender.state == .on
        })
        
        self.resourcesDownloadable = self.contents.filter{$0.isSelected == true}.count > 0
        tableView.reloadData()
    }
    
    @IBAction func downloadForSelectedResources(_ sender: Any) {
        self.view.wantsLayer = true
        let transition = CATransition()
        transition.subtype = CATransitionSubtype.fromLeft
        transition.type = CATransitionType(rawValue: "rippleEffect") // cube oglFlip rippleEffect pageCurl pageUnCurl
        transition.duration = 1.5
        view.layer?.add(transition, forKey: nil)
        contents.forEach({ (movie) in
            if movie.isSelected {
                movie.download()
            }
        })
    }
    
    @IBAction func research(_ sender: NSButton) {
        guard let spider = currentSpider else {return}
        switch spider.status {
        case .sniffing, .fetching:
            spider.abortSinffing()
        default:
            spider.restartSniffing(self)
        }

    }

    fileprivate func onContentsCountChanged() {
        
        guard let spider = currentSpider else {return}
        
        if contents.count == 0 {
            tableView.enclosingScrollView?.isHidden = true
            switch spider.status {
            case .sniffing, .fetching:
                promptLabel.stringValue = "资源搜索中🔍"
            default:
                promptLabel.stringValue = "Oops, 没有发现资源！"
                break
            }
            promptLabel.isHidden = false
            
        }else {
            promptLabel.isHidden = true
            tableView.enclosingScrollView?.isHidden = false
        }
        
        self.countLabel.stringValue = "\(self.contents.count)"
        resourcesAvailable = contents.count > 0
    }
    
    init() {
        super.init(nibName: "MovieViewController", bundle: Bundle(for: type(of:self)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentSpider = spiders[0]
    }
    
}

// MARK: -
extension MovieViewController: MovieTableCellViewDelegate {
    func handleMovieDownload(_ cell: MovieTableCellView) {
        guard let movie = cell.objectValue as? Movie else {return}
        movie.download()
    }
    
    func movieCellSelectionDidChange(_ cell: MovieTableCellView) {
        guard let movie = cell.objectValue as? Movie else {return}
        movie.isSelected = cell.checkbox.state == .on
        DispatchQueue.main.async {
            self.resourcesDownloadable = self.contents.filter{ $0.isSelected == true}.count > 0
        }
    }
}

// MARK: -
extension MovieViewController: RefreshableScrollViewDelegate {
    func scrollviewPullToResfresh(_ scrollview: RefreshableScrollView) {
        guard let spider = currentSpider else {return}
        switch spider.status {
        case .fetching, .sniffing:
            return
        default:
            currentSpider?.fetchMoreResources()
        }
    }
}

// MARK: -
extension MovieViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        guard  row < contents.count else {return nil}
        
        guard let cellView = tableView.makeView(withIdentifier: .movieTableCellView, owner: self) as? MovieTableCellView else {
            return nil
        }
        cellView.delegate = self
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard  row < contents.count else {return nil}
        return contents[row]
    }
}

// MARK: -
extension MovieViewController: SpiderDelegate {

    
    func spiderStartSniffing(_ spider: Spider) {
        DispatchQueue.main.async {
            self.isSniffing = true
            self.contents.removeAll()
            self.onContentsCountChanged()
        }
    }
    
    func spiderFinishSniffing(_ spider: Spider) {
        DispatchQueue.main.async {
            self.isSniffing = false
            if let resources = spider.resources {
                let res = resources.compactMap({ (res) -> Movie? in
                    return Movie(with: res, selection: false)
                })
                self.contents = res
            }
            self.onContentsCountChanged()
        }
    }

    func spiderStartFetching(_ spider: Spider) {
        DispatchQueue.main.async {
            self.isSniffing = true
            self.onContentsCountChanged()
        }

    }
    
    func spiderFinishFetching(spider: Spider, discoverd resources: [DownloadResource]) {
        let newRes = resources.compactMap({ (res) -> Movie? in
            return Movie(with: res, selection: false)
        })
        
        DispatchQueue.main.async {
            
            self.isSniffing = false

            let start = self.contents.count
            self.contents.append(contentsOf: newRes)
            let end = self.contents.count
            
            self.tableView.reloadData(forRowIndexes: IndexSet(integersIn: start..<end ), columnIndexes: IndexSet(integer: 0))
            self.onContentsCountChanged()
        }
 
    }
}
