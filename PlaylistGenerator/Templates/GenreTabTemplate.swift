//
//  GenreDataTemplate.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 20/11/2024.
//

import SwiftUI

struct GenreTabView: NSViewRepresentable {
    @ObservedObject var coordinator: Coordinator

    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSSearchFieldDelegate, ObservableObject {
        var data = [String]()
        @Published var filteredData = [String]() // Records to display on search
        @Published var checkedItems = Set<String>()  // Track which rows are checked
        @Published var isLoading = false
//        var isLoading = false
        var errorList = [String]()
        var isErrors = false
        var allSongFiles = [SongFile]()
        
        
        override init() {
            super.init()
            if getMusicFolderLocation() != "" {
                Task {
                    await updateData()
                }
            }
        }
        
        func updateData() async {
            if getMusicFolderLocation() != "" {
                await loadGenreTags()
            }
            
        }
        
        func loadGenreTags() async{
            DispatchQueue.main.async {
                self.isLoading = true
            }
            self.allSongFiles = getFileNames(target: "Songs")
            let dataAndErrors = await loadAllGenreData(songFiles: allSongFiles)
            let genreData = dataAndErrors["genre"] ?? []
            if dataAndErrors["errors"] != nil {
                errorList.append(contentsOf: dataAndErrors["errors"]!)
                isErrors = true
            }
            DispatchQueue.main.async {
                self.data = genreData
                self.filteredData = self.data
                self.isLoading = false
            }
            for error in errorList {
                print("Couldn't load genre for \(error)")
            }
        }
        
        func toggleCheckAllFilteredItems() {
            if self.checkedItems.isSuperset(of: Set(self.filteredData)) {
                self.checkedItems.subtract(Set(self.filteredData))
            // otherwise add all the data to checked items
            } else {
                    self.checkedItems.formUnion(Set(self.filteredData))
            }
        }
        
        func toggleDisplaySelectedItems() {
            if Set(self.filteredData) == self.checkedItems || self.checkedItems.isEmpty{
                self.filteredData = self.data
            } else {
                self.filteredData = Array(self.checkedItems).sorted(by: { $0 < $1 })
            }
        }
        
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            filteredData.count
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            
            let checkbox = NSButton(checkboxWithTitle: filteredData[row], target: self, action: #selector(checkboxToggled(_:)))
            checkbox.tag = row
            checkbox.state = checkedItems.contains(filteredData[row]) ? .on : .off
            
            return checkbox
        }
                
        @objc func checkboxToggled(_ sender: NSButton) {
            DispatchQueue.main.async {
                let item = self.filteredData[sender.tag]
                
                if self.checkedItems.contains(item) {
                    self.checkedItems.remove(item)
                } else {
                    self.checkedItems.insert(item)
                }
            }
        }
        
        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            toggleCheckbox(forRow: row, inTableView: tableView)
            return false
        }
        
        private func toggleCheckbox(forRow row: Int, inTableView tableView: NSTableView) {
            let item = filteredData[row]
            
            if checkedItems.contains(item) {
                checkedItems.remove(item)
            } else {
                checkedItems.insert(item)
            }
            
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
        
        func getSelectedItems() -> Set<String> {
                return checkedItems
        }
        
//        function to handle search bar
        func controlTextDidChange(_ notification: Notification) {
            // Get the search field object from the notification
            if let searchField = notification.object as? NSSearchField {
                let searchText = searchField.stringValue.lowercased()
                if searchText == "" {
                    filteredData = Array(data)
                } else {
                    filteredData = data.filter {
                        ($0.range(of: searchText, options: .caseInsensitive) != nil)
                    }
                }
                
                // Update table view data based on search
                if let tableView = searchField.superview?.subviews.compactMap({ $0 as? NSScrollView }).first?.documentView as? NSTableView {
                            tableView.reloadData()
                    }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return coordinator
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()
        let searchField = NSSearchField()
        
        searchField.placeholderString = "Search"
        searchField.delegate = context.coordinator
        searchField.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.headerView = nil
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Items"))
        column.title = "Items"
        tableView.addTableColumn(column)
        
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
  
        let stackView = NSStackView(views: [searchField, scrollView])
        stackView.orientation = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let containerScrollView = NSScrollView()
        containerScrollView.documentView = stackView
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor),

            searchField.heightAnchor.constraint(equalToConstant: 30),

            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
        ])
        
        return containerScrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let stackView = nsView.documentView as? NSStackView {
            // Find the NSTableView within the stack view's arrangedSubviews
            if let scrollView = stackView.arrangedSubviews.first(where: { $0 is NSScrollView }) as? NSScrollView {
                if let tableView = scrollView.documentView as? NSTableView {
                    tableView.reloadData() // Reload data on the table view
                }
            } else {
                print("NSTableView not found in stack view.")
            }
        } else {
            print("Document view is not an NSStackView.")
        }
        
    }

}


