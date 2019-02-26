//
//  TableDirector.swift
//  OSXTableKit
//
//  Created by Georgiy Malyukov on 22/02/2019.
//

import AppKit

public final class TableDirector: NSObject {
    
    private typealias RowData = (object: Any, path: IndexPath)
    
    public var isEmpty: Bool {
        return sections.isEmpty
    }
    
    public fileprivate(set) var sections = [TableSection]()
    public fileprivate(set) weak var tableView: NSTableView!
    public fileprivate(set) var selectedRow: Int?
    
    private var initialSelectDone = false
    private var rowsData = [RowData]()
    
    public init(with tableView: NSTableView, hideColumnHeaders: Bool = true) {
        super.init()
        self.tableView = tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableColumns.forEach {
            tableView.removeTableColumn($0)
        }
        tableView.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column")))
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = true
        if hideColumnHeaders {
            tableView.headerView = nil // hide columns if necessary
        }
    }
    
    public func reload() {
        _fillRowsData()
        tableView.reloadData()
        if !initialSelectDone && !tableView.allowsEmptySelection {
            tableView.selectRowIndexes([0], byExtendingSelection: false)
            initialSelectDone = true
        }
    }
    
    public func invoke(actions: [TableRowActionType], cell: NSTableCellView?, indexPath: IndexPath, userInfo: [AnyHashable: Any]? = nil) {
        guard let row = _row(at: indexPath).object as? Row else {
            return
        }
        actions.forEach { _ = row.invoke(action: $0, cell: cell, path: indexPath, userInfo: userInfo) }
    }
    
    @discardableResult
    public func invoke(action: TableRowActionType, cell: NSTableCellView?, indexPath: IndexPath, userInfo: [AnyHashable: Any]? = nil) -> Any? {
        guard let row = _row(at: indexPath).object as? Row else {
            return nil
        }
        return row.invoke(action: action, cell: cell, path: indexPath, userInfo: userInfo)
    }
    
}

extension TableDirector {
    
    @discardableResult
    public func append(section: TableSection) -> Self {
        append(sections: [section])
        return self
    }
    
    @discardableResult
    public func append(sections: [TableSection]) -> Self {
        self.sections.append(contentsOf: sections)
        return self
    }
    
    @discardableResult
    public func append(rows: [Row]) -> Self {
        append(section: TableSection(rows: rows))
        return self
    }
    
    @discardableResult
    public func insert(section: TableSection, atIndex index: Int) -> Self {
        sections.insert(section, at: index)
        return self
    }
    
    @discardableResult
    public func replaceSection(at index: Int, with section: TableSection) -> Self {
        if index < sections.count {
            sections[index] = section
        }
        return self
    }
    
    @discardableResult
    public func delete(sectionAt index: Int) -> Self {
        sections.remove(at: index)
        return self
    }
    
    @discardableResult
    public func remove(sectionAt index: Int) -> Self {
        return delete(sectionAt: index)
    }
    
    @discardableResult
    public func clear() -> Self {
        sections.removeAll()
        return self
    }
    
}

extension TableDirector {
    
    private func _fillRowsData() {
        rowsData.removeAll()
        var i = 0
        var j = 0
        for section in sections {
            rowsData.append((section, IndexPath(item: j, section: i)))
            i += 1
            j = 0
            for item in section.rows {
                rowsData.append((item, IndexPath(item: j, section: i)))
                j += 1
            }
        }
    }
    
    private func _row(at indexPath: IndexPath) -> RowData {
        return rowsData.first { $0.path == indexPath }!
    }
    
    private func _makeView(for row: Int) -> NSTableCellView {
        // swiftlint:disable force_cast
        if let row = rowsData[row].object as? Row {
            let cell = row.make()
            row.configure(cell: cell)
            return cell
        }
        // otherwise return header's view
        let view = (rowsData[row].object as! TableSection).headerView!
        view.reloadData()
        return view
        // swiftlint:enable force_cast
    }
    
    private func _section(for row: Int) -> TableSection? {
        return rowsData[row].object as? TableSection
    }
    
}

extension TableDirector: NSTableViewDataSource, NSTableViewDelegate {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return rowsData.count
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return _makeView(for: row)
    }
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let view = _makeView(for: row)
        view.layout()
        return view.fittingSize.height
    }
    
    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        guard (rowsData[row].object as? Row) != nil else {
            return false
        }
        let path = rowsData[row].path
        if let selectedRow = selectedRow {
            if let cell = tableView.view(atColumn: 0, row: selectedRow, makeIfNecessary: false) as? NSTableCellView {
                if selectedRow != row {
                    // not equal to selected row? Then just deselect the "old" row without "clicking" it
                    invoke(action: .deselect, cell: cell, indexPath: path, userInfo: nil)
                } else {
                    // equal to selected row? Then it was clicked actually, so send both "click" and "deselect" events
                    invoke(actions: [.click, .deselect], cell: cell, indexPath: path, userInfo: nil)
                }
                tableView.reloadData(forRowIndexes: [selectedRow], columnIndexes: [0])
            }
        }
        if selectedRow == nil || (selectedRow != nil && selectedRow! != row) {
            if let cell = tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView {
                invoke(actions: [.click, .select], cell: cell, indexPath: path, userInfo: nil)
                tableView.reloadData(forRowIndexes: [row], columnIndexes: [0])
            }
        }
        selectedRow = (row == selectedRow) ? nil : row
        return false
    }
    
}
