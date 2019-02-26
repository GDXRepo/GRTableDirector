//
//  TableCell.swift
//  OSXTableKit
//
//  Created by Georgiy Malyukov on 24/02/2019.
//

import AppKit

open class TableCell<T>: NSTableCellView, ConfigurableCell {
    
    public typealias CellData = T
    
    public var backgroundColor: NSColor = .clear {
        didSet {
            layer!.backgroundColor = backgroundColor.cgColor
        }
    }
    
    open func configure(with data: T) {
        // empty
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        make()
        bind()
        localize()
    }
    
    public required init?(coder decoder: NSCoder) {
        fatalError()
    }
    
    open func make() {
        // empty
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
    }
    
    open func bind() {
        // empty
    }
    
    open func localize() {
        // empty
    }
    
}
