//
//  GenreDataHelper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 20/11/2024.
//

import SwiftUI

func loadAllGenreData(songFiles: [SongFile]) async -> [String : [String]] {
    print("Loading Genres")
    var errorList = [String]()
    var genreSet = Set<String>()
    for song in songFiles{
        let errors = await song.fetchGenreData()
        errorList.append(contentsOf: errors)
        if !song.genreTags.contains("Unknown"){
            for genre in song.genreTags {
                genreSet.insert(genre)
            }
        }
    }
    let genreArray = Array(genreSet).sorted()
    print("Completed loading genres")
    return ["genre": genreArray, "errors": errorList]
}

func searchSongsForGenre(songFiles: [SongFile], genre: String?) async -> [SongFile] {
    var songs = songFiles
    // if genre is passed then we need to filter the songFiles for only songs of this genre
    if genre != nil {
        songs = songFiles.filter{ $0.genreTags.contains(genre!) }
    }
    
    let songsWithRating = await loadSongFileRatings(songs: songs)
    
    return songsWithRating
}

