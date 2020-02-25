//
//  ViewController.swift
//  iSpider
//
//  Created by jifu on 2018/11/2.
//  Copyright © 2018 Spider. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    fileprivate(set) var contents = [DownloadResource]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    lazy var spider: Spider = {
        let recommend = MovieRecommend()
        recommend.delegate = self
        return recommend
    }()


    
    private let cellId = "cellId"
    
    lazy var tableView: UITableView = {
        let v = UITableView(frame: .zero)
        v.register(TableResourceCell.self, forCellReuseIdentifier: self.cellId)
        v.delegate = self
        v.dataSource = self
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
        ])
        
        spider.startSniffing(self)
    }

}

extension ViewController: SpiderDelegate {
    func spiderStartSniffing(_ spider: Spider) {
        
    }
    
    func spiderFinishSniffing(_ spider: Spider) {
        self.contents = spider.resources ?? []
    }
    
    func spiderStartFetching(_ spider: Spider) {
        
    }
    
    func spiderFinishFetching(spider: Spider, discoverd resources: [DownloadResource]) {
        
    }
    
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func  tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
       
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? TableResourceCell else {return UITableViewCell()}
        cell.resource = contents[indexPath.item]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

