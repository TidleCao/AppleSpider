//
//  RefreshableScrollView.swift
//  Spider
//
//  Created by jifu on 2018/10/27.
//  Copyright © 2018 Spider. All rights reserved.
//

import Cocoa

protocol RefreshableScrollViewDelegate: class {
    func scrollviewPullToResfresh(_ scrollview: RefreshableScrollView)
}

// MARK: -
class RefreshableScrollView: NSScrollView {

    weak var delegate: RefreshableScrollViewDelegate?
    
    override func scrollWheel(with event: NSEvent) {
        let phase = event.phase 
        
        // start to refresh when trackingpad pull to end or mouse move to bottom
        if phase.contains(NSEvent.Phase.ended) || phase.rawValue == 0, let doucumentViewBounds = documentView?.bounds {
            if contentView.bounds.origin.y >= (doucumentViewBounds.size.height - contentView.bounds.size.height) {
                delegate?.scrollviewPullToResfresh(self)
            }
            
        }
        super.scrollWheel(with: event)
    }
    
}
