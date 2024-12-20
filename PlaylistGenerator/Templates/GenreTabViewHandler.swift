//
//  TabViewHandler.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 07/11/2024.
//
import AVFoundation
import SwiftUI


struct TabHandler : View {
    
    @State private var selectedItems = Set<SongFile>()
    @State private var selectedTab = "Artists"
    @State private var selectedAlbums = [String]()
    @State private var showAlert = false
    @State private var alertList = [String]()
    @State private var isLoading = false
    @State private var loadingComment = "Updating Genres"
    
    @State private var toggleButtonDict : [String : [String: Bool]] = ["Artist":["Select All" : false, "Toggle Selected" : false],
                                                                       "Album":["Select All" : false, "Toggle Selected" : false],
                                                                       "Song":["Select All" : false, "Toggle Selected" : false]]
    
    @ObservedObject var songCoordinator : SongTabView.SongCoordinator
    @ObservedObject var artistCoordinator : MusicFolderTabView.Coordinator
    @ObservedObject var albumCoordinator : MusicFolderTabView.Coordinator
    
    let tabOptions = ["Artists", "Albums"]
    
    var body: some View {
        
        NavigationStack {
            
            if isLoading {
                LoadingOverlay(comment: loadingComment, colour: Color.gray)
            } else {
                VStack{
                    
                    HStack {
                        
                        Spacer()
                        Button(action : {
                            Task {
                                artistCoordinator.updateData()
                                albumCoordinator.updateData()
                            }
                            
                        }){
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    TabView(selection: $selectedTab) {
                        
                        VStack(spacing: 20) {
                            
                            MusicFolderTabView(
                                selectedView: "Artists",
                                coordinator: artistCoordinator,
                                songCoordinator: songCoordinator
                            )
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            
                            HStack{
                                
                                Button(action : {
                                    toggleButtonDict["Artist"]!["Select All"]!.toggle()
                                    
                                    Task  {
                                        await artistCoordinator.toggleCheckAllFilteredItems()
                                    }
                                }) {
                                    Text(toggleButtonDict["Artist"]!["Select All"]! ? "Unselect All" : "Select All")
                                        .frame(width: 100)
                                }
                                .padding(.bottom, 10)
                                
                                Button(action : {
                                    let selectedCount = artistCoordinator.getSelectedItems().count
                                    let filteredCount = artistCoordinator.filteredData.count
                                    
                                    if selectedCount > 0 && !(filteredCount == selectedCount){
                                        toggleButtonDict["Artist"]!["Toggle Selected"]!.toggle()
                                    } else {
                                        toggleButtonDict["Artist"]!["Toggle Selected"]! = false
                                    }
                                    
                                    artistCoordinator.toggleDisplaySelectedItems()
                                    if artistCoordinator.filteredData.count > artistCoordinator.getSelectedItems().count {
                                        toggleButtonDict["Artist"]!["Select All"]! = false
                                    } else {
                                        toggleButtonDict["Artist"]!["Select All"]! = true
                                    }
                                }) {
                                    Text(toggleButtonDict["Artist"]!["Toggle Selected"]! ? "Show All" : "View Selected")
                                        .frame(width: 100)
                                    }
                                    .padding(.bottom, 10)
                                
                            }
                            
                        }
                        .tabItem { Text("Artists") }
                        .tag("Artists")
                        
                        HStack(spacing: 20) {
                            
                            VStack{
                                
                                MusicFolderTabView(
                                    selectedView: "Albums",
                                    coordinator: albumCoordinator,
                                    songCoordinator: songCoordinator
                                )
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                
                                HStack {
                                    
                                    Button(action : {
                                        toggleButtonDict["Album"]!["Select All"]!.toggle()
                                        Task  {
                                            self.loadingComment = "Fetching all songs"
                                            self.isLoading = true
                                            await albumCoordinator.toggleCheckAllFilteredItems()
                                            self.isLoading = false
                                        }
                                    }) {
                                        Text(toggleButtonDict["Album"]!["Select All"]! ? "Unselect All" : "Select All")
                                            .frame(width: 100)
                                    }
                                    .padding(.bottom, 10)
                                    
                                    Button(action : {
                                        let selectedCount = albumCoordinator.selectedAlbums.count
                                        let filteredCount = albumCoordinator.filteredData.count
                                        
                                        if selectedCount > 0 && !(filteredCount == selectedCount){
                                            toggleButtonDict["Album"]!["Toggle Selected"]!.toggle()
                                        } else {
                                            toggleButtonDict["Album"]!["Toggle Selected"]! = false
                                        }
                                        
                                        albumCoordinator.toggleDisplaySelectedItems()
                                        if albumCoordinator.filteredData.count > albumCoordinator.selectedAlbums.count {
                                            toggleButtonDict["Album"]!["Select All"]! = false
                                        } else {
                                            toggleButtonDict["Album"]!["Select All"]! = true
                                        }
                                    }) {
                                        Text(toggleButtonDict["Album"]!["Toggle Selected"]! ? "Show All" : "View Selected")
                                            .frame(width: 100)
                                    }
                                    .padding(.bottom, 10)
                                    
                                }
                                
                            }
                            
                            VStack{
                                
                                SongTabView(songCoordinator: songCoordinator)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                
                                HStack{
                                    
                                    Button(action : {
                                        toggleButtonDict["Song"]!["Select All"]!.toggle()
                                        songCoordinator.toggleAllFilteredSongs()
                                    }) {
                                        Text(toggleButtonDict["Song"]!["Select All"]! ? "Unselect All" : "Select All")
                                            .frame(width: 100)
                                    }
                                    .padding(.bottom, 10)
                
                                    Button(action : {
                                        let selectedCount = songCoordinator.getSelectedItems().count
                                        let filteredCount = songCoordinator.filteredData.count
                                        
                                        if selectedCount > 0 && !(filteredCount == selectedCount){
                                            toggleButtonDict["Song"]!["Toggle Selected"]!.toggle()
                                        } else {
                                            toggleButtonDict["Song"]!["Toggle Selected"]! = false
                                        }
                                        
                                        songCoordinator.toggleDisplaySelectedItems()
                                        if songCoordinator.filteredData.count > songCoordinator.getSelectedItems().count {
                                            toggleButtonDict["Song"]!["Select All"]! = false
                                        } else {
                                            toggleButtonDict["Song"]!["Select All"]! = true
                                        }
                                    }) {
                                        Text(toggleButtonDict["Song"]!["Toggle Selected"]! ? "Show All" : "View Selected")
                                            .frame(width: 100)
                                    }
                                    .padding(.bottom, 10)
                                    
                                }
                                
                            }
                            
                        }
                        .tabItem { Text("Albums") }
                        .tag("Albums")
                    }
                    
                    Button("Submit") {
                        var coordinator : MusicFolderTabView.Coordinator
                        if selectedTab == "Artists" {
                            coordinator = artistCoordinator
                        } else {
                            coordinator = albumCoordinator
                        }
                        let selection = coordinator.getSelectedItems()
                        selectedItems = selection
                        Task {
                            self.loadingComment = "Updating Genres"
                            self.isLoading = true
                            await updateSongGenres(files: Array(selection))
                            self.isLoading = false
                        }
                    }
                    .sheet(isPresented: $showAlert) {
                        ListAlertView(items: alertList)
                            .frame(width: 400, height: 400)
                    }
                    
                }
                .padding(10)
            }
            
            Spacer()
                .frame(height: 10)
            
        }
        .onChange(of: albumCoordinator.checkedItems) { initialSelection, newSelection in
            
            updateToggleButtons(albumArtistCoordinator: albumCoordinator, initialSelection: initialSelection, newSelection: newSelection, type: "Album")
            
        }
        .onChange(of: artistCoordinator.checkedItems) { initialSelection, newSelection in
            
            updateToggleButtons(albumArtistCoordinator: artistCoordinator, initialSelection: initialSelection, newSelection: newSelection, type: "Artist")
            
        }
        .onChange(of: songCoordinator.checkedItems) { initialSelection, newSelection in
            
            updateToggleButtons(songCoordinator: songCoordinator, initialSelection: initialSelection, newSelection: newSelection, type: "Song")
            
        }
        .onAppear {
            // update the toggle buttons when the user selects the view so they match what has been previously selected
            updateToggleButtons(albumArtistCoordinator: albumCoordinator, type: "Album")
            updateToggleButtons(songCoordinator: songCoordinator, type: "Song")
            updateToggleButtons(albumArtistCoordinator: artistCoordinator, type: "Artist")
            
        }
    }
    
    // update toggle button logic for when the view page is selected
    func updateToggleButtons(albumArtistCoordinator : MusicFolderTabView.Coordinator? = nil, songCoordinator : SongTabView.Coordinator? = nil, type : String) {
        
        let selectedItemsCount = albumArtistCoordinator != nil ? type == "Album" ? albumArtistCoordinator!.selectedAlbums.count : albumArtistCoordinator!.getSelectedItems().count : songCoordinator!.getSelectedItems().count
        let filteredItemsCount = albumArtistCoordinator != nil ? albumArtistCoordinator!.filteredData.count : songCoordinator!.filteredData.count
        let totalItemsCount = albumArtistCoordinator != nil ? albumArtistCoordinator!.data.count : songCoordinator!.data.count
        
        if filteredItemsCount != selectedItemsCount {
            toggleButtonDict[type]!["Select All"] = false
        } else {
            toggleButtonDict[type]!["Select All"] = true
        }
        
        if filteredItemsCount == totalItemsCount || (selectedItemsCount==0 && filteredItemsCount == totalItemsCount) || filteredItemsCount != selectedItemsCount {
            toggleButtonDict[type]!["Toggle Selected"] = false
        } else {
            toggleButtonDict[type]!["Toggle Selected"] = true
        }
        
    }
    
    func updateToggleButtons<T: Hashable>(albumArtistCoordinator : MusicFolderTabView.Coordinator? = nil, songCoordinator : SongTabView.Coordinator? = nil, initialSelection : Set<T>, newSelection : Set<T>, type : String) {
        
        let filteredItemsCount = albumArtistCoordinator != nil ? albumArtistCoordinator!.filteredData.count : songCoordinator!.filteredData.count
        let totalItemsCount = albumArtistCoordinator != nil ? albumArtistCoordinator!.data.count : songCoordinator!.data.count
        
        if toggleButtonDict.keys.contains(type) {
            if newSelection.count > 0 && newSelection.count == filteredItemsCount {
                toggleButtonDict[type]!["Select All"] = true
                toggleButtonDict[type]!["Toggle Selected"] = true
            }
            
            if newSelection.count < initialSelection.count && filteredItemsCount != newSelection.count {
                toggleButtonDict[type]!["Select All"] = false
                
                if newSelection.count == 0 && filteredItemsCount < totalItemsCount {
                    toggleButtonDict[type]!["Toggle Selected"] = true
                } else {
                    toggleButtonDict[type]!["Toggle Selected"] = false
                }
            }
            
            if newSelection.count < filteredItemsCount && newSelection.count != 0{
                toggleButtonDict[type]!["Toggle Selected"] = false
            }
            
            if newSelection.count == filteredItemsCount && filteredItemsCount == totalItemsCount{
                toggleButtonDict[type]!["Toggle Selected"] = false
            }
        }
        
    }

    
    func updateSongGenres(files: [SongFile]) async {
        
        let sortedURLS = sortURLs(files: files)
        let mp3URLs = sortedURLS.0
        let nonMp3URLs = sortedURLS.1
        
        let updateErrors = await updateTags(mp3URLs: mp3URLs, nonMp3URLs: nonMp3URLs)
        
        if !updateErrors.isEmpty{
            alertList = updateErrors
            showAlert = true
        }
        
    }
    
    func sortURLs(files: [SongFile]) -> ([URL],[URL]) {
        
        var mp3URLs = [URL]()
        var nonMp3URLs = [URL]()
        for file in files {
            if file.artistBool{
                // load all albums for the artist
                let albumURLs = getSubFolderLocations(folder: file.url)
                //load songs for each album and append
                for album in albumURLs{
                    _ = readFolderNames(folder: album.relativePath, type: "Albums").map {
                        if $0.url.pathExtension == "mp3"{
                            mp3URLs.append($0.url)
                        } else {
                            nonMp3URLs.append($0.url)
                        }
                    }
                }
            } else {
                if file.url.pathExtension == "mp3"{
                    mp3URLs.append(file.url)
                } else {
                    nonMp3URLs.append(file.url)
                }
            }
        }
        
        return (mp3URLs, nonMp3URLs)
        
    }
    
    func updateTags(mp3URLs: [URL], nonMp3URLs: [URL]) async -> [String]{
        
        // Use ID3 to update mp3 files and AVFoundation for non mp3
        var errors = [String]()
        
        if mp3URLs.count > 0 {
            let updates = await updateID3GenreTags(fileURLs: mp3URLs)
            if !updates.isEmpty {
                print("Errors updating the below mp3 files")
                updates.forEach{print($0)}
            }
            errors.append(contentsOf: updates)
        }
        
        if nonMp3URLs.count > 0 {
            let updates = await updateAVGenreTags(fileURLs: nonMp3URLs)
            if !updates.isEmpty {
                print("Errors updating the below non-mp3 files")
                updates.forEach{print($0)}
            }
            errors.append(contentsOf: updates)
        }
        return errors
        
    }
}
