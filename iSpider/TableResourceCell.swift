//
//  TableResourceCell.swift
//  iSpider
//
//  Created by jifu on 2019/11/25.
//  Copyright © 2019 Spider. All rights reserved.
//

import UIKit

class TableResourceCell: UITableViewCell {
    
    let nameLabel: UILabel = {
       let label = UILabel()
       label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let sizeLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        addSubview(sizeLabel)
        addSubview(nameLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 50),
            nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            sizeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor, constant: 0),
            sizeLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
        ])
    }
    
    var resource: DownloadResource? {
        didSet {
            if let resource = resource {
                nameLabel.text = resource.name
                sizeLabel.text = "size: \(resource.size ?? "0KB")"
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            
        }
    }
    
    override var isSelected: Bool {
        didSet {
            
        }
    }
}
