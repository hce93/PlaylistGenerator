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

    
    @ObservedObject var songCoordinator : SongTabView.SongCoordinator
    @ObservedObject var artistCoordinator : MusicFolderTabView.Coordinator
    @ObservedObject var albumCoordinator : MusicFolderTabView.Coordinator
    
    let tabOptions = ["Artists", "Albums"]
    
    var body: some View {
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
                        .padding(20)
                        HStack{
                            Button("Select/Unselect All") {
                                Task { await artistCoordinator.toggleCheckAllFilteredItems() }
                            }
                            Button("Toggle Selected Artists") {
                                artistCoordinator.toggleDisplaySelectedItems()
                            }
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
                            .padding(20) // 5% margin in points
                            HStack {
                                Button("Select/Unselect All") {
                                    Task{
                                        self.loadingComment = "Fetching all songs"
                                        self.isLoading = true
                                        await albumCoordinator.toggleCheckAllFilteredItems()
                                        self.isLoading = false
                                    }
                                    
                                }
                                Button("Toggle Selected Albums") {
                                    albumCoordinator.toggleDisplaySelectedItems()
                                }
                            }
                            
                        }
                        VStack{
                            SongTabView(songCoordinator: songCoordinator)
                                .padding(20) // 5% margin in points
                            HStack{
                                Button("Select/Unselect All") {
                                    songCoordinator.toggleAllFilteredSongs()
                                }
                                Button("Toggle Selected Songs") {
                                    songCoordinator.toggleDisplaySelectedItems()
                                }
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
