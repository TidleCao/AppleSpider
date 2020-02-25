//
//  Sniffer.swift
//  sniffer
//
//  Created by jifu on 2018/10/31.
//  Copyright © 2018 Spider. All rights reserved.
//

import Foundation

class Sniffer: XLPluginBaseController, XLPluginPageProtocol {
    var host: (XLHostPageProtocol&XLHostSkinProtocol ){
        return self.hostController() as! (XLHostPageProtocol&XLHostSkinProtocol )
    }
    
    lazy var pageItem: XLNavigationItemView = {
        let item = host.makeNavigationItem(withIdentifer: self.identifier()!, title: "资源嗅探")
        return item!
    }();
    
    lazy var viewController: MovieViewController = {
        let vc = MovieViewController()
        return vc
    }()
    
    func navigationItems() -> [Any]! {
       return [pageItem]
    }
    
    func toolbarView(forItem item: Any!) -> NSView! {
        return nil
    }
    
    func contentView(forItem item: Any!) -> NSView! {
        return viewController.view
    }
    
    private func bundleImage(with name: String) -> NSImage? {
        return Bundle(for: type(of: self)).image(forResource: name)
    }
    
    override func userChangeSkinNotification(_ notification: Notification!) {
        if host.skinIdentifier.hasSuffix("black") {
            pageItem.image = bundleImage(with: "nav_search_black")
        }else{
            pageItem.image = bundleImage(with: "nav_search_white")
        }
        let textSelectedColor = self.host.fontColor(forKey: "NavigationItemSelectText")
        let textDeSelectedColor = self.host.fontColor(forKey: "NavigationItemText")
        pageItem.selectedColor = textSelectedColor
        pageItem.deSelectedColor = textDeSelectedColor

        pageItem.alternateImage = bundleImage(with: "nav_search_sel")
        
    }
    
}


