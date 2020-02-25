//
//  MovieTableCellView.swift
//  Spider
//
//  Created by jifu on 2018/10/24.
//  Copyright © 2018 Spider. All rights reserved.
//

import Cocoa

protocol MovieTableCellViewDelegate: class {
    func handleMovieDownload(_ cell: MovieTableCellView)
    func movieCellSelectionDidChange(_ cell: MovieTableCellView)
}

// MARK: -
class MovieTableCellView: NSTableCellView {
    weak var delegate: MovieTableCellViewDelegate?
    
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var sizeTextField: NSTextField!
    
    @IBOutlet weak var downloadBtn: NSButton! {
        didSet {
            downloadBtn.target = self
            downloadBtn.action = #selector(download(_:))
        }
    }
    
    @IBOutlet weak var checkbox: NSButton! {
        didSet {
            checkbox.target = self
            checkbox.action = #selector(changeSelection(_:))
        }
    }
    
    @objc func changeSelection(_ sender: NSButton!) {
        delegate?.movieCellSelectionDidChange(self)
    }
    
    @objc func download(_ sender: NSButton!) {

        delegate?.handleMovieDownload(self)
    }
    
    override var objectValue: Any? {
        didSet {
            guard let movie = objectValue as? Movie else {return}
            nameTextField?.stringValue = movie.downloadResouce?.name ?? ""
            sizeTextField?.stringValue = movie.downloadResouce?.size ?? ""
            checkbox.state = movie.isSelected ? .on : .off
        }
    }
}
