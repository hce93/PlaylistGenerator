//
//  ContentView.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 21/10/2024.
//

import SwiftUI


struct ContentView : View {
    @StateObject private var artistCoordinatorGenreView : MusicFolderTabView.Coordinator
    @StateObject private var albumCoordinatorGenreView : MusicFolderTabView.Coordinator
    @StateObject private var songCoordinatorGenreView : SongTabView.SongCoordinator
    @StateObject private var artistCoordinatorPlaylistView : MusicFolderTabView.Coordinator
    @StateObject private var albumCoordinatorPlaylistView : MusicFolderTabView.Coordinator
    @StateObject private var songCoordinatorPlaylistView : SongTabView.SongCoordinator
    @StateObject private var genreCoordinator = GenreTabView.Coordinator()
    @StateObject private var playlistSettings = PlaylistSettings()
    @State private var currentDisplay : String = "Home"
    @State private var currentMusicFolder: String = getMusicFolderLocation()
    
    init() {
        let initialSongCoordinatorGenreView = SongTabView.SongCoordinator()
        _artistCoordinatorGenreView = StateObject(wrappedValue: MusicFolderTabView.Coordinator(selectedView: "Artists", songCoordinator: initialSongCoordinatorGenreView))
        _albumCoordinatorGenreView = StateObject(wrappedValue: MusicFolderTabView.Coordinator(selectedView: "Albums", songCoordinator: initialSongCoordinatorGenreView))
        _songCoordinatorGenreView = StateObject(wrappedValue: initialSongCoordinatorGenreView)
        
        let initialSongCoordinatorPlaylistView = SongTabView.SongCoordinator()
        _artistCoordinatorPlaylistView = StateObject(wrappedValue: MusicFolderTabView.Coordinator(selectedView: "Artists", songCoordinator: initialSongCoordinatorPlaylistView))
        _albumCoordinatorPlaylistView = StateObject(wrappedValue: MusicFolderTabView.Coordinator(selectedView: "Albums", songCoordinator: initialSongCoordinatorPlaylistView))
        _songCoordinatorPlaylistView = StateObject(wrappedValue: initialSongCoordinatorPlaylistView)
        
    }
    
    var body : some View {
        NavigationSplitView {
           List {
               Button(action: {updateDisplay(display: "Home")}) {
                   Text("Home")
               }
               .buttonStyle(PlainButtonStyle())
               Button(action: {updateDisplay(display: "Info")}) {
                   Text("Info")
               }
               .buttonStyle(PlainButtonStyle())
               Button(action: {updateDisplay(display: "updateGenre")}) {
                   Text("Update Genres")
               }
               .buttonStyle(PlainButtonStyle())
               .disabled(currentMusicFolder == "")
               Button(action: {updateDisplay(display: "playlist")}) {
                   Text("Create New Playlists")
               }
               .buttonStyle(PlainButtonStyle())
               .disabled(currentMusicFolder == "")
           }
           .listStyle(SidebarListStyle())
           .navigationTitle("Menu")
       } detail: {
           detailView
       }
       .onChange(of: currentMusicFolder) {
           if currentMusicFolder != "" {
               updateCoordinators()
           }
       }
       .frame(minWidth: 1050, maxWidth: .infinity, minHeight: 650, maxHeight: .infinity)
    }
    
    private var detailView: some View {
        switch currentDisplay {
        case "Info":
            return AnyView(Info())
//        case "setFolder":
//            return AnyView(SetLibraryFolder(currentMusicFolder: $currentMusicFolder))
        case "updateGenre":
            return AnyView(UpdateGenre(artistCoordinator: artistCoordinatorGenreView, albumCoordinator: albumCoordinatorGenreView, songCoordinator: songCoordinatorGenreView))
        case "playlist":
            return AnyView(CreatePlaylist(artistCoordinator: artistCoordinatorPlaylistView, albumCoordinator: albumCoordinatorPlaylistView, genreCoordinator: genreCoordinator, playlistSettings: playlistSettings))
        default:
            return AnyView(Home(currentMusicFolder: $currentMusicFolder))
            
        }
    }
    
    private func updateCoordinators() {
        artistCoordinatorGenreView.updateData()
        albumCoordinatorGenreView.updateData()
        artistCoordinatorPlaylistView.updateData()
        albumCoordinatorPlaylistView.updateData()
        Task{await genreCoordinator.updateData()}
    }
    
    func updateDisplay(display: String) {
        currentDisplay = display
    }
}



