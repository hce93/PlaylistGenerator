//
//  SongCoordinator.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 10/11/2024.
//
import SwiftUI

struct SongTabView: NSViewRepresentable {
    @ObservedObject var songCoordinator: SongCoordinator
    
    class SongCoordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSSearchFieldDelegate, ObservableObject {
        var selectedAlbums = Set<SongFile>()
        var data = [SongFile]()
        @Published var filteredData = [SongFile]() // Records to display on search
        @Published var checkedItems = Set<SongFile>()  // Track which rows are checked
        var selectedView: String = ""
        //below is used to store song data when not in use so we dont have to constantly read files everytime we need the data
        var temporaryDataStore = Set<SongFile>()
        
        func updateSelectedAlbums(album: SongFile, add: Bool) {
            if self.selectedAlbums.contains(album) {
                self.selectedAlbums.remove(album)
            } else {
                self.selectedAlbums.insert(album)
            }
            self.updateSongList(alteredAlbum: album, add: add)
        }
        
        func updateSongList(alteredAlbum: SongFile, add: Bool){
            if add {
                // check if songs we need are already in the data store
                var songsToAdd = Array(self.temporaryDataStore.filter({ $0.album == alteredAlbum.album && $0.artist == alteredAlbum.artist}))
                if songsToAdd.count <= 0 {
                    songsToAdd = readFolderNames(folder: alteredAlbum.url.relativePath, type: "Songs")
                    self.temporaryDataStore.formUnion(songsToAdd)
                }
                self.data.append(contentsOf: songsToAdd)
                self.data = self.data.sorted(by: { $0.name < $1.name })
                self.filteredData = self.data
                self.checkedItems.formUnion(songsToAdd)
            } else {
                self.data.removeAll { $0.album == alteredAlbum.album && $0.artist == alteredAlbum.artist}
                self.filteredData = self.data
                self.checkedItems.subtract(self.checkedItems.filter({ $0.album == alteredAlbum.album && $0.artist == alteredAlbum.artist }))
            }
        }
        
        func toggleAllSongsByAlbums(albums: Set<SongFile>) async {
            //update song list with all selected albums
            if albums.isEmpty {
                self.data = []
                await MainActor.run {
                    self.filteredData = []
                    self.checkedItems = Set()
                }
                self.selectedAlbums = Set()
            } else {
                let albumsToAdd = albums.subtracting(self.selectedAlbums)
                let albumsToRemove = self.selectedAlbums.subtracting(albums)
                //remove songs
                let albumNames = albumsToRemove.map{ $0.album }
                self.data = self.data.filter{ !albumNames.contains($0.album)}
                
                //add songs
                if !albumsToAdd.isEmpty {
                    var newSongs = [SongFile]()
                    for album in albumsToAdd {
                        var songsToAdd = Array(self.temporaryDataStore.filter({ $0.album == album.album && $0.artist == album.artist }))
                        if songsToAdd.count <= 0 {
                            songsToAdd = readFolderNames(folder: album.url.relativePath, type: "Songs")
                            self.temporaryDataStore.formUnion(songsToAdd)
                        }
//                        let albumURL = album.url
//                        let songsToAdd = readFolderNames(folder: albumURL.relativePath, type: "Songs")
                        newSongs.append(contentsOf: songsToAdd)
                    }
                    self.data.append(contentsOf: newSongs)
                    self.data = self.data.sorted(by: { $0.name < $1.name })
                }
            
                await MainActor.run {
                    self.filteredData = self.data
                    self.checkedItems = Set(self.data)
                }
                self.selectedAlbums = albums
            }
        }
        
        func toggleAllFilteredSongs(albums: [SongFile] = []) {
            if self.checkedItems == Set(filteredData) {
                self.checkedItems = Set()
            } else {
                self.checkedItems = Set(filteredData)
            }
        }
        
        func toggleDisplaySelectedItems() {
            if Set(self.filteredData) == self.checkedItems || self.checkedItems.isEmpty{
                self.filteredData = self.data
            } else {
                self.filteredData = Array(self.checkedItems).sorted(by: { $0.name < $1.name })
            }
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
        
        @objc func checkboxToggled(_ sender: NSButton) {
            let item = filteredData[sender.tag]
            
            if checkedItems.contains(item) {
                checkedItems.remove(item)
            } else {
                checkedItems.insert(item)
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
        
        func getSelectedItems() -> Set<SongFile> {
            return checkedItems
        }
        
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
    
    func makeCoordinator() -> SongCoordinator {
        return songCoordinator
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
        scrollView.translatesAutoresizingMaskIntoConstraints = false

  
        let stackView = NSStackView(views: [searchField, scrollView])
        stackView.orientation = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false

        
        let containerScrollView = NSScrollView()
        containerScrollView.documentView = stackView
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerScrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor),

            // Make the search field take its intrinsic height
            searchField.heightAnchor.constraint(equalToConstant: 30),

            // Allow the scroll view to take up all remaining space
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
        ])
        
        return containerScrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Access the NSStackView as the document view
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
