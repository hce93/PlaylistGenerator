//
//  PlaylistHelper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 29/11/2024.
//

import SwiftUI
import MusicKit
import MediaPlayer
import Foundation


func generatePlaylist(songDict : [String : [SongFile]], artistLength: Int, albumLength: Int, genreLength: Int) -> [SongFile] {
    //set an initial minimum rating for songs to be added to the playlist
        // we will reduce until the playlist is full or all songs are included
    var minRating = 4.0
    var playlist = [SongFile]()
    
    var albumCount = 0
    var artistCount = 0
    var genreCount = 0
    var playlistCount = 0
    let playlistSize = artistLength + albumLength + genreLength
    
    let albumSongs = songDict["album"] ?? []
    let artistSongs = songDict["artist"] ?? []
    let genreSongs = songDict["genre"] ?? []
    
    let songCount = artistSongs.count + genreSongs.count + albumSongs.count
    
    if songCount <= playlistSize {
        print("Requested playlist size was \(playlistSize) and we found only \(songCount) songs. Returning all songs.")
        let allSongs = songDict.map(\.value).flatMap(\.self)
        return allSongs
    }

    var albumSongsSortedByAlbums = sortAndGroupSongs(songs: albumSongs, by: "Album")
    var artistSongsSortedByArtists = sortAndGroupSongs(songs: artistSongs)
    var genreSongsSortedByArtists = sortAndGroupSongs(songs: genreSongs)
    
    let genreArtists = genreSongsSortedByArtists.keys
    var genreDetail = Dictionary(
        uniqueKeysWithValues: genreArtists.map {
            ($0, ["foundSong": false, "minRating": minRating])
        }
    )
    let artistArtists = artistSongsSortedByArtists.keys
    var artistDetail = Dictionary(
        uniqueKeysWithValues: artistArtists.map {
            ($0, ["foundSong": false, "minRating": minRating])
        }
    )
    let albumAlbums = albumSongsSortedByAlbums.keys
    var albumDetail = Dictionary(
        uniqueKeysWithValues: albumAlbums.map {
            ($0, ["foundSong": false, "minRating": minRating])
        }
    )
    
    while playlistCount < playlistSize {
        
        //Loop through selected artists first so songs from those artists are guaranteed to be in the playlist
        albumLoop: for album in albumAlbums {
            if albumCount >= albumLength {
                break
            } else if albumSongsSortedByAlbums[album]!.isEmpty{
                continue
            } else {
                addNextSongToPlaylist(artist: album, type: "album", detail: &albumDetail, sortedSongs: &albumSongsSortedByAlbums)
            }
        }
        
        //Loop through selected artists first so songs from those artists are guaranteed to be in the playlist
        artistLoop: for artist in artistArtists {
            if artistCount >= artistLength {
                break
            } else if artistSongsSortedByArtists[artist]!.isEmpty{
                continue
            } else {
                addNextSongToPlaylist(artist: artist, type: "artist", detail: &artistDetail, sortedSongs: &artistSongsSortedByArtists)
            }
        }
        
        // loop through genre songs
        genreLoop: for artist in genreArtists {
            if genreCount >= genreLength {
                break
            } else if genreSongsSortedByArtists[artist]!.isEmpty{
                continue
            } else {
                addNextSongToPlaylist(artist: artist, type: "genre", detail: &genreDetail, sortedSongs: &genreSongsSortedByArtists)
            }
        }
    }
    return playlist
    
    func addNextSongToPlaylist(artist: String, type: String, detail : inout [Dictionary<String, [SongFile]>.Keys.Element : [String : Any]], sortedSongs : inout [String : [SongFile]]){
            
        var toBeRemoved = [Int]()
            // if we havent found a song yet then loop through the songs
        var foundSongForArtist = false
        while !foundSongForArtist{
            let currentArtistMinRating = detail[artist]?["minRating"] as? Double ?? minRating
            for song in sortedSongs[artist]! {
                //if song meats the minimum required rating then add it to the playlist

                if song.fetchRating() >= currentArtistMinRating {
                    playlist.append(song)
                    toBeRemoved.append(sortedSongs[artist]!.firstIndex(of: song)!)
                    if type == "artist" {
                        artistCount += 1
                    } else if type == "album" {
                        albumCount += 1
                    } else {
                        genreCount += 1
                    }
                    playlistCount += 1
                    foundSongForArtist = true
                    break
                }
            }
            // reduce the min rating for the artist if a song hasn't been found and then start the artist's song loop again
            if !foundSongForArtist{
                detail[artist]?["minRating"] = currentArtistMinRating - 0.5
            }
        }
        //remove songs from artist array if we have added it to the playlist
        for i in toBeRemoved.indices {
            sortedSongs[artist]?.remove(at: toBeRemoved[i])
        }
    }
}

func sortAndGroupSongs(songs: [SongFile], by: String = "artist") -> [String : [SongFile]] {
    // shuffle songs at first so the order of the dictionary is random
    let shuffledSongs = songs.shuffled()
    if by == "Album" {
        var songsByAlbums = Dictionary(grouping: shuffledSongs) { $0.album }
        songsByAlbums = songsByAlbums.mapValues{
            $0.shuffled()
        }
        return songsByAlbums
    } else {

        var songsByArtists = Dictionary(grouping: shuffledSongs) { $0.artist }
        songsByArtists = songsByArtists.mapValues{
            $0.shuffled()
        }
        return songsByArtists
    }
}

//function to submit playlist using Apple Script.
    // we use apple script as we
func submitPlaylist(playlistName: String, URLs: [URL]) -> Bool{
    
    var appleScript = """
        tell application "Music"
            set newPlaylist to make new user playlist with properties {name:"\(playlistName)"}
            try\n
        """
    for url in URLs {
        appleScript += """
             add (POSIX file "\(url.path)" as alias) to newPlaylist\n
            """
    }
    appleScript += """
            on error errMsg
                display dialog "Error adding songs: " & errMsg
            end try
        end tell
        """
    print(appleScript)
    if let script = NSAppleScript(source: appleScript) {
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript execution failed: \(error)")
            if error["NSAppleScriptErrorNumber"] as? Int == -1743 {
                //display a message to the user to enable automation permissions
                let alert = NSAlert()
                alert.messageText = "Permission Required"
                alert.informativeText = """
                    Please enable the automation permission for this app to interact with Apple Music. 
                    Go to System Preferences > Security & Privacy > Privacy > Automation.
                """
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            
            return false
        } else {
            print("Playlist created successfully!")
        }
    } else {
        print("Failed to create NSAppleScript instance.")
        return false
    }
    return true
}

