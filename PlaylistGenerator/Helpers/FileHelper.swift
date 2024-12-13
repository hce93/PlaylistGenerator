//
//  FileHelper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 23/10/2024.
//

import SwiftUI

class SongFile : CustomStringConvertible, Hashable, Identifiable{
    var url : URL
    var artistBool : Bool
    var name = ""
    var artist = ""
    var album = ""
    var genreTags = [String] ()
    var validFileTags = ["aif", "aiff", "m4a", "caf", "wav"]
    private var rating = -1.0
    
    init(url: URL, artistBool: Bool = false, albumBool: Bool = false){
        self.url = url
        self.artistBool = artistBool
        // if 2nd to last path component is equal to the music folder location then we have an artist
        if url.pathComponents[url.pathComponents.count - 2] == URL(fileURLWithPath: getMusicFolderLocation()).lastPathComponent {
            self.name = url.lastPathComponent
            self.artist = url.lastPathComponent
        // if 3rd to last path component is the main music folder then we have an album
        } else if url.pathComponents[url.pathComponents.count - 3] == URL(fileURLWithPath: getMusicFolderLocation()).lastPathComponent {
            self.name = url.pathComponents.suffix(2).joined(separator: " - ")
            self.album = url.pathComponents[url.pathComponents.count - 1]
            self.artist = url.pathComponents[url.pathComponents.count - 2]
        } else {
            self.name = url.pathComponents.suffix(2).joined(separator: " - ")
            self.album = url.pathComponents[url.pathComponents.count - 2]
            self.artist = url.pathComponents[url.pathComponents.count - 3]
        }
    }
    
    func getTitle() async -> String{
        var title = ""
        if url.pathExtension == "mp3" {
            do{
                title = try await getMp3Title(url: url)
            } catch {
                print("Errors getting mp3 title: \(error)")
            }
        } else {
            title = getNonMp3Title(url: url)
        }
        return title
    }
    
    func fetchGenreData() async -> [String]{
        var errorList = [String]()
        var data = [String: [String]]()
        // need to return errors lists from below 2 functiond
        if self.url.pathExtension == "mp3" {
            data = await getMp3GenreTags(url: self.url)
        }
        else if self.validFileTags.contains(self.url.pathExtension) {
            data = await getNonMp3GenreTags(url: self.url)
        }
        self.genreTags = data["genre"] ?? []
        errorList.append(contentsOf: data["errors"] ?? [])
        return errorList
    }
    
    var description: String {
            return name
        }
    
    static func == (lhs: SongFile, rhs: SongFile) -> Bool {
        return lhs.url == rhs.url && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(name)
    }
    
    func fetchRating() -> Double {
        return self.rating
    }
    
    func updateRating(rating: Double) -> Bool {
        if self.rating >= 0 {
            // if rating has already been set dont allow it to be changed again
            return false
        } else {
            self.rating = rating
            return true
        }
    }
}

func loadSongFileRatings(songs: [SongFile]) async -> [SongFile] {
    for song in songs {
        let title = await song.getTitle()
        let rating = song.fetchRating()
        if rating < 0.0 {
            await getSongRating(song: song)
        }
    }
    return songs
}

func saveMusicFolderLocation(_ url: String, persistPermissions: Bool) {
    
    UserDefaults.standard.set(url, forKey: "musicFolderLocation")
    
    // Create a bookmark for security-scoped access
    do {
        let folderURL = URL(fileURLWithPath: url)
        let bookmarkData = try folderURL.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(bookmarkData, forKey: "folderBookmark")
        UserDefaults.standard.synchronize()
    } catch {
        print("Error creating bookmark: \(error)")
    }
//    UserDefaults.standard.synchronize()
    
}

func getMusicFolderLocation() -> String {
    UserDefaults.standard.synchronize()
    if let path = UserDefaults.standard.string(forKey: "musicFolderLocation"),
       let bookmarkData = UserDefaults.standard.data(forKey: "folderBookmark") {
        
        do {
            var isStale = false
            // Resolve the bookmark data
            let folderURL = try URL(resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            // Check if bookmark data is stale
            if isStale {
                print("Bookmark data is stale. Please select the folder again.")
                return ""
            }
            
            // Use the resolved URL
            return folderURL.path
        } catch {
            print("Error resolving bookmark: \(error)")
        }
    }
    
    print("Folder not found in UserDefaults.")
    return ""
}

func isMusicFolderSet() -> Bool {
    return !getMusicFolderLocation().isEmpty
}

func readFolderNames(folder : String?, type: String?) -> [SongFile] {
    var files = [SongFile]()
    let folderURL = URL(fileURLWithPath: folder ?? getMusicFolderLocation())
    let fileURLs = getSubFolderLocations(folder: folderURL)
    if type == "Albums" || type == "Songs" {
        
        files = fileURLs.map{ url in
            url.lastPathComponent == "Folder.jpg" ? nil : SongFile(url: url, albumBool: type=="Albums")
        }.compactMap { $0 }
    } else {
        files = fileURLs.map{ SongFile(url: $0, artistBool: true)
        }
    }
    return files
}

func getSubFolderLocations(folder: URL) -> [URL] {
    let fileManager = FileManager.default
    var fileURLs = [URL]()
    do{
        fileURLs = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        fileURLs = fileURLs.filter { $0.lastPathComponent != ".DS_Store"}
        if fileURLs.isEmpty {
            print("Deleting Folder.jpg at \(folder.relativePath)")
            try fileManager.removeItem(at: folder)
            return []
        } else if fileURLs.count == 1 {
            if fileURLs[0].lastPathComponent == "Folder.jpg" {
                print("Deleting Folder.jpg at \(fileURLs[0].relativePath)")
                try fileManager.removeItem(at: folder)
                return []
            }
        }
    } catch {
        print("Errors loading sub folder URLs: \(error)")
    }
    return fileURLs
}

func getFileNames(target: String, albums: [SongFile]?=nil, artists: [SongFile]?=nil) -> [SongFile] {
    var fileNames = [SongFile]()
    let musicFolderLocation = getMusicFolderLocation()
    
    if target == "Artists" {
        fileNames = readFolderNames(folder: musicFolderLocation, type: target)
    } else if target == "Albums" {
        let artistURLs = getSubFolderLocations(folder: URL(fileURLWithPath: musicFolderLocation))
        for url in artistURLs {
            fileNames.append(contentsOf: readFolderNames(folder: url.path, type: target))
        }
    } else if target == "Songs" {
        let albumURLs = getFileNames(target: "Albums")
        for album in albumURLs {
            fileNames.append(contentsOf: readFolderNames(folder: album.url.path, type: target))
        }
    }
    return fileNames
}
