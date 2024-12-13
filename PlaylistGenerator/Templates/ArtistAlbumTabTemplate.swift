//
//  test.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 05/11/2024.
//

import SwiftUI

struct MusicFolderTabView: NSViewRepresentable {
    @State var selectedView = "Artist"
    @ObservedObject var coordinator: Coordinator
    @ObservedObject var songCoordinator: SongTabView.SongCoordinator
    
    class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSSearchFieldDelegate, ObservableObject {
        @Published var selectedAlbums = Set<SongFile>()
//        var data = [SongFile]()
        @Published var filteredData = [SongFile]() // Records to display on search
        @Published var checkedItems = Set<SongFile>()  // Track which rows are checked
        var selectedView: String
        var songCoordinator: SongTabView.SongCoordinator
        var data = [SongFile]()

        
        init(selectedView: String, songCoordinator: SongTabView.SongCoordinator ) {
            
            self.selectedView = selectedView
            self.songCoordinator = songCoordinator
            super.init()
            if getMusicFolderLocation() != "" {
                updateData()
            }
        }
        
        func updateData() {
            self.data = getFileNames(target: selectedView).sorted(by: { $0.name < $1.name})
            self.filteredData = data
        }
        
        func numberOfRows(in tableView: NSTableView) -> Int {
            filteredData.count
        }
        
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            
            let checkbox = NSButton(checkboxWithTitle: filteredData[row].name, target: self, action: #selector(checkboxToggled(_:)))
            checkbox.tag = row
            checkbox.state = checkedItems.contains(filteredData[row]) ? .on : .off
            return checkbox
        }
        
        func toggleCheckAllFilteredItems() async {
            // if checked items contians the filtered data then we want to remove this subset from the checked items
            if self.checkedItems.isSuperset(of: Set(self.filteredData)) {
                await MainActor.run {
                    self.checkedItems.subtract(Set(self.filteredData))
                }
            // otherwise add all the data to checked items
            } else {
                await MainActor.run {
                    self.checkedItems.formUnion(Set(self.filteredData))
                }
            }
            
            // update selected albums according to what we have done above and then pass this info to the song coordinator
            if self.selectedView == "Albums" {
                await MainActor.run {
                    self.selectedAlbums = self.checkedItems
                }
                await self.songCoordinator.toggleAllSongsByAlbums(albums: self.selectedAlbums)
            }
        }

        func toggleDisplaySelectedItems() {
            if Set(self.filteredData) == self.checkedItems || self.checkedItems.isEmpty{
                self.filteredData = self.data
            } else {
                self.filteredData = Array(self.checkedItems).sorted(by: { $0.name < $1.name})
            }
        }
                
        @objc func checkboxToggled(_ sender: NSButton) {
            DispatchQueue.main.async {
                let item = self.filteredData[sender.tag]
                
                //update selected albums/artists depending on the view
                if self.checkedItems.contains(item) {
                    self.checkedItems.remove(item)
                } else {
                    self.checkedItems.insert(item)
                }
                
                // update song coordinator if using album view
                if self.selectedView == "Albums" {
                    if self.selectedAlbums.contains(item) {
                        self.selectedAlbums.remove(item)
                        self.songCoordinator.updateSelectedAlbums(album: item, add: false)
                    } else {
                        self.selectedAlbums.insert(item)
                        self.songCoordinator.updateSelectedAlbums(album: item, add: true)
                    }
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
            
            if self.selectedView == "Albums" {
                if self.selectedAlbums.contains(item) {
                    self.selectedAlbums.remove(item)
                    self.songCoordinator.updateSelectedAlbums(album: item, add: false)
                } else {
                    self.selectedAlbums.insert(item)
                    self.songCoordinator.updateSelectedAlbums(album: item, add: true)
                }
            }
            
            tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integer: 0))
        }
        
        func getSelectedItems() -> Set<SongFile> {
            if selectedView == "Albums" {
                return songCoordinator.getSelectedItems()
            } else {
                return checkedItems
            }
            
        }
        
//        function to handle search bar
        func controlTextDidChange(_ notification: Notification) {
            // Get the search field object from the notification
            if let searchField = notification.object as? NSSearchField {
                let searchText = searchField.stringValue.lowercased()
                if searchText == "" {
                    filteredData = data
                } else {
                    filteredData = data.filter { $0.name.lowercased().contains(searchText) }
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
        scrollView.wantsLayer = true
        if let layer = scrollView.layer {
            layer.cornerRadius = 10 // Adjust as needed
            layer.borderWidth = 1   // Optional, for a visible border
            layer.borderColor = NSColor.gray.cgColor // Adjust color as needed
            layer.masksToBounds = true // Ensures the content is clipped to the rounded border
        }
        
        let stackView = NSStackView(views: [searchField, scrollView])
        stackView.orientation = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        if let stackLayer = stackView.layer {
            stackLayer.cornerRadius = 10 // Adjust as needed
            stackLayer.borderWidth = 1   // Optional, for a visible border
            stackLayer.borderColor = NSColor.gray.cgColor // Adjust color as needed
            stackLayer.masksToBounds = true // Ensures the content is clipped to the rounded border
        }
        
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


