//
//  CreatePlaylist.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 22/10/2024.
//

import SwiftUI
import MusicKit
import AppKit

struct PlaylistTableRow {
    var title: String
    var album: String
    var artist: String
    var isChecked: Bool
    var url: URL
}

class PlaylistSettings: ObservableObject {
    @Published var songPerArtist: Int = 0
    @Published var songPerAlbum: Int = 0
    @Published var songPerGenre: Int = 0
    @Published var selection = 20
    
    init(songPerArtist: Int = 0, songPerAlbum: Int = 0, songPerGenre: Int = 0, selection: Int = 20) {
        self.songPerArtist = songPerArtist
        self.songPerAlbum = songPerAlbum
        self.songPerGenre = songPerGenre
        self.selection = selection
    }
}

struct CreatePlaylist : View {
    @State private var currentMusicFolder: String = ""
    @ObservedObject var artistCoordinator : MusicFolderTabView.Coordinator
    @ObservedObject var albumCoordinator : MusicFolderTabView.Coordinator
    @ObservedObject var genreCoordinator : GenreTabView.Coordinator
    @ObservedObject var playlistSettings : PlaylistSettings
    
    @State private var playlistLoading = false
    
    @State private var artistSelected = false
    @State private var albumSelected = false
    @State private var genreSelected = false
    
    @State private var artistSelectAll = false
    @State private var artistToggleSelected = false
    @State private var albumSelectAll = false
    @State private var albumToggleSelected = false
    @State private var genreSelectAll = false
    @State private var genreToggleSelected = false
    
    let playlistLengths = Array(stride(from: 5, through: 60, by: 5))
    let playlistProportions = Array(stride(from: 5, through: 60, by: 5))
    
    @State private var playlistName : String = ""
    @State private var playlistSongFiles = [SongFile]()
    @State private var playlistTableData: [PlaylistTableRow] = []
    
    var body : some View {
        NavigationStack {
            if currentMusicFolder == ""{
                Text("Please set your library folder before continuing")
            } else if genreCoordinator.isLoading{
                LoadingOverlay(comment: "This could take a minute or so depending on the size of your music library", colour: Color.black)
            } else if playlistLoading {
                LoadingOverlay(comment: "Generating playlist", colour: Color.gray)
            }
            else {
                GeometryReader { geometry in
                    VStack{
                        HStack {
                            Spacer()
                            Button(action : {
                                artistCoordinator.updateData()
                                albumCoordinator.updateData()
                                Task{await genreCoordinator.updateData()}
                                playlistSongFiles = []
                                playlistTableData = []
                            }){
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        HStack{
                            VStack(alignment: .leading){
                                Text("Artists")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                MusicFolderTabView(
                                    selectedView: "Artists",
                                    coordinator: artistCoordinator,
                                    songCoordinator: artistCoordinator.songCoordinator
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                HStack {
                                    Button(action : {
                                        artistSelectAll.toggle()
                                        Task  {
                                            await artistCoordinator.toggleCheckAllFilteredItems()
                                        }
                                    }) {
                                        Text(artistSelectAll ? "Unselect All" : "Select All")
                                            .frame(width: 100)
                                    }
                                    Button(action : {
                                        artistSelectAll = true
                                        if artistCoordinator.getSelectedItems().count > 0 {
                                            artistToggleSelected.toggle()
                                        } else {
                                            artistToggleSelected = false
                                        }
                                        artistCoordinator.toggleDisplaySelectedItems()
                                    }) {
                                        Text(artistToggleSelected ? "Show All" : "View Selected")
                                            .frame(width: 100)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Stepper {
                                    Text("% in playlist: \(playlistSettings.songPerArtist)%")
                                } onIncrement: {
                                    if artistSelected && (playlistSettings.songPerArtist + 5 <= 100) && (genreSelected || albumSelected){
                                        playlistSettings.songPerArtist += 5
                                        if (playlistSettings.songPerGenre - 5 >= 0) && genreSelected {
                                            playlistSettings.songPerGenre -= 5
                                        }
                                        if playlistSettings.songPerArtist + playlistSettings.songPerAlbum + playlistSettings.songPerGenre > 100{
                                            playlistSettings.songPerAlbum = 100 - playlistSettings.songPerArtist - playlistSettings.songPerGenre
                                        }
                                    }
                                } onDecrement: {
                                    if artistSelected && (playlistSettings.songPerArtist - 5 >= 0) && (genreSelected || albumSelected){
                                        playlistSettings.songPerArtist -= 5
                                        if (playlistSettings.songPerGenre + 5 <= 100) && genreSelected {
                                            playlistSettings.songPerGenre += 5
                                        }
                                        if playlistSettings.songPerArtist + playlistSettings.songPerAlbum + playlistSettings.songPerGenre < 100{
                                            playlistSettings.songPerAlbum = 100 - playlistSettings.songPerArtist - playlistSettings.songPerGenre
                                        }
                                    }
                                }
                                .frame(height: 20)
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            
                            VStack(alignment: .leading){
                                Text("Albums")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                MusicFolderTabView(
                                    selectedView: "Albums",
                                    coordinator: albumCoordinator,
                                    songCoordinator: albumCoordinator.songCoordinator
                                )
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                HStack {
                                    
                                    Button(action : {
                                        albumSelectAll.toggle()
                                        Task  {
                                            await albumCoordinator.toggleCheckAllFilteredItems()
                                        }
                                    }) {
                                        Text(albumSelectAll ? "Unselect All" : "Select All")
                                            .frame(width: 100)
                                    }
                                    Button(action : {
                                        albumSelectAll = true
                                        if albumCoordinator.getSelectedItems().count > 0 {
                                            albumToggleSelected.toggle()
                                        } else {
                                            albumToggleSelected = false
                                        }
                                        albumCoordinator.toggleDisplaySelectedItems()
                                    }) {
                                        Text(albumToggleSelected ? "Show All" : "View Selected")
                                            .frame(width: 100)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Stepper {
                                    Text("% in playlist: \(playlistSettings.songPerAlbum)%")
                                } onIncrement: {
                                    if albumSelected && (playlistSettings.songPerAlbum + 5 <= 100) && (genreSelected || artistSelected){
                                        playlistSettings.songPerAlbum += 5
                                        if (playlistSettings.songPerGenre - 5 >= 0) && genreSelected{
                                            playlistSettings.songPerGenre -= 5
                                        }
                                        if playlistSettings.songPerArtist + playlistSettings.songPerAlbum + playlistSettings.songPerGenre > 100{
                                            playlistSettings.songPerArtist = 100 - playlistSettings.songPerAlbum - playlistSettings.songPerGenre
                                        }
                                    }
                                } onDecrement: {
                                    if albumSelected && (playlistSettings.songPerAlbum - 5 >= 0) && (genreSelected || artistSelected){
                                        playlistSettings.songPerAlbum -= 5
                                        if (playlistSettings.songPerGenre + 5 <= 100) && genreSelected {
                                            playlistSettings.songPerGenre += 5
                                        }
                                        if playlistSettings.songPerArtist + playlistSettings.songPerAlbum + playlistSettings.songPerGenre < 100{
                                            playlistSettings.songPerArtist = 100 - playlistSettings.songPerAlbum - playlistSettings.songPerGenre
                                        }
                                    }
                                }
                                .frame(height: 20)
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            
                            VStack(alignment: .leading){
                                Text("Genres")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                GenreTabView(coordinator: genreCoordinator)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                HStack {
                                    Button(action : {
                                        genreSelectAll.toggle()
                                        genreCoordinator.toggleCheckAllFilteredItems()
                                    }) {
                                        Text(genreSelectAll ? "Unselect All" : "Select All")
                                            .frame(width: 100)
                                    }
                                    Button(action : {
                                        genreSelectAll = true
                                        if genreCoordinator.getSelectedItems().count > 0 {
                                            genreToggleSelected.toggle()
                                        } else {
                                            genreToggleSelected = false
                                        }
                                        genreCoordinator.toggleDisplaySelectedItems()
                                    }) {
                                        Text(genreToggleSelected ? "Show All" : "View Selected")
                                            .frame(width: 100)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text("% in playlist: \(playlistSettings.songPerGenre)%")
                                    .frame(height: 20)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            
                        }
                        .frame(height: geometry.size.height * 0.45)
                        
                        VStack {
                            Picker("Number of songs in playlist", selection: $playlistSettings.selection) {
                                ForEach(playlistLengths, id: \.self) {
                                    Text("\($0)")
                                }
                            }
                            .frame(width: 225)
                            
                            Spacer()
                                .frame(height: 20)
                            
                            Button("Generate Playlist") {
                                let artists = artistCoordinator.getSelectedItems()
                                let artistArray = artists.map{ $0.artist }
                                let albums = albumCoordinator.getSelectedItems()
                                let albumsArray = albums.map{ $0.album }
                                let genres = genreCoordinator.getSelectedItems()
                                let allSongs = genreCoordinator.allSongFiles
                                let playlistLength = playlistSettings.selection
                                let artistLength = Int(playlistLength * playlistSettings.songPerArtist / 100)
                                let albumLength = Int(playlistLength * playlistSettings.songPerAlbum / 100)
                                let genreLength = playlistLength - artistLength - albumLength
                                
                                Task{
                                    playlistLoading = true
                                    playlistSongFiles = await handleSubmitToGeneratePlaylist(genres: genres, allSongs: allSongs, size: playlistLength, artists: artistArray, albums: albumsArray, artistLength: artistLength, albumLength: albumLength, genreLength: genreLength)
                                    playlistTableData = await getPlaylistTableData(playlist: playlistSongFiles)
                                    playlistLoading = false
                                }
                                
                            }
                        }
                        Spacer()
                            .frame(height: 20)
                        VStack {
                            TextField("Playlist Name", text: $playlistName)
                                .multilineTextAlignment(.center) // Aligns the text to the center
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 350)
                            PlaylistTableViewWrapper(data: $playlistTableData)
                        }

                        VStack {
                            
                            HStack{
                                Button(action : {
                                    Task{
                                        await selectSongToAddToPlaylist()
                                    }
                                }) {
                                    Text("Add Song To Playlist")
                                        .frame(width: 125)
                                }
                                
                                Button(action : {
                                    let selected = playlistTableData.filter{ $0.isChecked }
                                    let selectedURLs = selected.map{ $0.url }
                                    _ = submitPlaylist(playlistName: $playlistName.wrappedValue, URLs: selectedURLs)
                                }) {
                                    Text("Save Playlist")
                                        .frame(width: 125)
                                }
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
        .onChange(of: genreCoordinator.checkedItems) { initialSelection, newSelection in
            genreSelected = newSelection.count > 0
            if newSelection.count > 0 {
                playlistSettings.songPerGenre = 100 - playlistSettings.songPerAlbum - playlistSettings.songPerArtist
                
                if genreCoordinator.getSelectedItems().count == genreCoordinator.filteredData.count {
                    genreToggleSelected = true
                    genreSelectAll = true
                }
            } else {
                playlistSettings.songPerGenre = 0
                if artistSelected {
                    playlistSettings.songPerArtist = 100 - playlistSettings.songPerAlbum
                } else if albumSelected {
                    playlistSettings.songPerAlbum = 100
                }
            }
            if newSelection.count < initialSelection.count {
                genreSelectAll = false
                
                if newSelection.count == 0 && genreCoordinator.filteredData.count < genreCoordinator.data.count {
                    genreToggleSelected = true
                } else {
                    genreToggleSelected = false
                }
            }
        }
        .onChange(of: artistCoordinator.checkedItems) { initialSelection, newSelection in
            artistSelected = newSelection.count > 0
            if newSelection.count > 0 {
                playlistSettings.songPerArtist = 100 - playlistSettings.songPerAlbum - playlistSettings.songPerGenre
                
                if artistCoordinator.getSelectedItems().count == artistCoordinator.filteredData.count {
                    artistToggleSelected = true
                    artistSelectAll = true
                }
            } else {
                playlistSettings.songPerArtist = 0
                if albumSelected {
                    playlistSettings.songPerAlbum = 100 - playlistSettings.songPerGenre
                } else if genreSelected {
                    playlistSettings.songPerGenre = 100
                }
            }
            if newSelection.count < initialSelection.count {
                artistSelectAll = false
                
                if newSelection.count == 0 && artistCoordinator.filteredData.count < artistCoordinator.data.count {
                    artistToggleSelected = true
                } else {
                    artistToggleSelected = false
                }
            }
        }
        .onChange(of: albumCoordinator.checkedItems) { initialSelection, newSelection in
            albumSelected = newSelection.count > 0
            if newSelection.count > 0 {
                playlistSettings.songPerAlbum = 100 - playlistSettings.songPerArtist - playlistSettings.songPerGenre
                
                if newSelection.count == albumCoordinator.filteredData.count {
                    albumToggleSelected = true
                    albumSelectAll = true
                }
            } else {
                playlistSettings.songPerAlbum = 0
                if artistSelected {
                    playlistSettings.songPerArtist = 100 - playlistSettings.songPerGenre
                } else if genreSelected {
                    playlistSettings.songPerGenre = 100
                }
            }
            if newSelection.count < initialSelection.count {
                albumSelectAll = false
                
                if newSelection.count == 0 && albumCoordinator.filteredData.count < albumCoordinator.data.count {
                    albumToggleSelected = true
                } else {
                    albumToggleSelected = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            // Listen for UserDefaults changes
            currentMusicFolder = getMusicFolderLocation()
        }
        .onAppear {
            currentMusicFolder = getMusicFolderLocation()
        }
    }
    
    func selectSongToAddToPlaylist() async {
        let songURLs = await openAddSongPanel()
        if !songURLs.isEmpty {
            playlistLoading = true
            for url in songURLs {
                let song = SongFile(url: url)
                playlistSongFiles.append(song)
                let row = await generatePlaylistTableRow(song: song)
                playlistTableData.append(row)
            }
            playlistLoading = false
        }
    }
}

func sortSongsForPlaylistGenerator(allSongs: [SongFile], genres: Set<String>, artists: [String], albums: [String], artistLength: Int, albumLength: Int, genreLength: Int) async -> [String : [SongFile]]{

    //use a set for genre songs originally to ensure no song duplicates across multiple genres
    var genreSongs = Set<SongFile>()
    
    let albumSongs = allSongs.filter { albums.contains($0.album) }
    let artistSongs = allSongs.filter { artists.contains($0.artist) && !albums.contains($0.album) }
    let allSongsExclArtistSongs = allSongs.filter { !artistSongs.contains($0) }
    for genre in genres {
        let genreSongsToBeFiltered = allSongsExclArtistSongs.filter{ $0.genreTags.contains(genre) }
        genreSongs.formUnion(Set(genreSongsToBeFiltered.filter{ !artistSongs.contains($0) }))
    }
    
    let songDict = ["genre" : Array(genreSongs), "artist" : artistSongs, "album" : albumSongs]
    
    return songDict
}


func handleSubmitToGeneratePlaylist(genres: Set<String>, allSongs: [SongFile], size: Int, artists: [String], albums: [String], artistLength: Int, albumLength: Int, genreLength: Int) async -> [SongFile] {
    
    var filterdSongDict = await sortSongsForPlaylistGenerator(allSongs: allSongs, genres: genres, artists: artists, albums: albums, artistLength: artistLength, albumLength: albumLength, genreLength: genreLength)
    
    let count = filterdSongDict.values.flatMap{ $0 }.count
    if count <= size {
        print("Requested playlist size was \(size) and we found only \(count) songs. Returning all songs.")
        return filterdSongDict.values.flatMap{ $0 }
    } else {
        for key in filterdSongDict.keys {
            if !filterdSongDict[key]!.isEmpty {
                filterdSongDict[key] = await loadSongFileRatings(songs: filterdSongDict[key]!)
            }
        }
            
        let playlist = generatePlaylist(songDict: filterdSongDict, artistLength: artistLength, albumLength: albumLength, genreLength: genreLength)
        print("Playlist created with \(playlist.count) songs: ")
        for item in playlist{
            print("\(item.artist) - \(item.album) - \(item.name) added to playlist with rating: \(item.fetchRating())")
        }
        
        return playlist
    }
}

func getPlaylistTableData(playlist: [SongFile]) async -> [PlaylistTableRow]{
    var playlistData = [PlaylistTableRow]()
    for song in playlist {
//        await playlistData.append(PlaylistTableRow(title: song.getTitle(), album: song.album, artist: song.artist, isChecked: true, url: song.url))
        let row = await generatePlaylistTableRow(song: song)
        playlistData.append(row)
    }
    return playlistData
}

func generatePlaylistTableRow(song: SongFile) async -> PlaylistTableRow{
    let row =  await PlaylistTableRow(title: song.getTitle(), album: song.album, artist: song.artist, isChecked: true, url: song.url)
    return row
}

func openAddSongPanel() async -> [URL] {
// used continuation to ensure async is adhered to as NSOpenPanel is callback based
    return await withCheckedContinuation{ continuation in
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.title = "Choose a song"
            panel.message = "Select the song you wish to add to the playlist"
            panel.prompt = "Select File"
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = true
            panel.canCreateDirectories = false
            
            panel.begin { response in
                if response == .OK {
                    continuation.resume(returning: panel.urls)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
        
    }
}
