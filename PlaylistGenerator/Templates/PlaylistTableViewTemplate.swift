//
//  PlaylistTableView.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 02/12/2024.
//

import SwiftUI

struct PlaylistTableViewWrapper: NSViewRepresentable {
    @Binding var data: [PlaylistTableRow]
    
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var parent: PlaylistTableViewWrapper
        var data: [PlaylistTableRow]
        weak var tableView: NSTableView?
        
        init(_ parent: PlaylistTableViewWrapper) {
            self.parent = parent
            self.data = parent.data
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            data.count
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let identifier = tableColumn?.identifier.rawValue ?? ""
            let value = data[row]
            
            if identifier == "Title" {
                return createTextCell(text: value.title)
            } else if identifier == "Album" {
                return createTextCell(text: value.album)
            } else if identifier == "Artist" {
                return createTextCell(text: value.artist)
            } else if identifier == "Select" {
                let button = NSButton()
                button.setButtonType(.switch)
                button.state = value.isChecked ? .on : .off
                button.tag = row // Set row index for reference
                button.action = #selector(toggleCheckbox(_:))
                button.target = self
                button.title = ""
                return button
            }
            return nil
        }
        
        func getSelected() -> [PlaylistTableRow]{
            let selected = data.filter{ $0.isChecked }
            return selected
        }
        
        @objc private func toggleCheckbox(_ sender: NSButton) {
            let row = sender.tag
            if row >= 0 && row < data.count {
                data[row].isChecked = sender.state == .on
                parent.data = data // Update the binding
            }
        }
        
        private func createTextCell(text: String) -> NSTextField {
            let textField = NSTextField(labelWithString: text)
            textField.isBordered = false
            textField.isEditable = false
            textField.backgroundColor = .clear
            return textField
        }
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let tableView = NSTableView()
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        // Add Columns
        let columns = ["Title", "Album", "Artist", "Select"]
        for (index, title) in columns.enumerated() {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(title))
            column.title = title

            if index == 3 {
                column.width = 50
                column.minWidth = 50
                column.maxWidth = 50
                column.dataCell = NSButtonCell() // Checkbox
                (column.dataCell as? NSButtonCell)?.title = "" // No text
                (column.dataCell as? NSButtonCell)?.setButtonType(.switch)
            } else {
                column.resizingMask = .autoresizingMask
            }

            tableView.addTableColumn(column)
        }

        scrollView.documentView = tableView
        context.coordinator.tableView = tableView

        scrollView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { _ in
            self.adjustColumnWidths(for: tableView, in: scrollView)
        }

        return scrollView
    }

    func adjustColumnWidths(for tableView: NSTableView, in scrollView: NSScrollView) {
        guard let superviewWidth = scrollView.superview?.frame.width else { return }
        let totalWidth = superviewWidth
        let fixedColumnWidth: CGFloat = 50 // Width of "Select" column
        let flexibleWidth = totalWidth - fixedColumnWidth
        let flexibleColumnCount = 3
        let flexibleColumnWidth = max(flexibleWidth / CGFloat(flexibleColumnCount), 0)

        for (index, column) in tableView.tableColumns.enumerated() {
            if index == 3 {
                column.width = fixedColumnWidth
            } else {
                column.width = flexibleColumnWidth
            }
        }
    }

    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.data = data
        context.coordinator.tableView?.reloadData()
        
        if let tableView = context.coordinator.tableView {
                adjustColumnWidths(for: tableView, in: nsView)
            }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
