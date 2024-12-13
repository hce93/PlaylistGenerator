//
//  MusicBeanzHelper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 31/10/2024.
//

import SwiftUI
import Foundation

enum NoGenreError: Error {
    case noGenreReturned(String)
}

enum NoSongError: Error {
    case noSongReturned(String)
}

struct Release: Codable {
    let id: String
    let primaryType: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case primaryType = "primary-type"
    }
}

struct MusicBrainzReleaseResponse: Codable{
    let releaseGroups: [Release]
    
    enum CodingKeys: String, CodingKey {
        case releaseGroups = "release-groups"
    }
}

struct Genre: Codable {
    let name: String
    let count: Int?
}

struct MusicBeanzGenreResponse: Codable {
    let genres: [Genre]
}

struct RecordingReleaseResponse: Codable {
    let title: String
}

struct Recording: Codable {
    let id : String
    let title : String
    let releases : [RecordingReleaseResponse]
}

struct MusicBrainzRecordingResponse: Codable {
    let recordings : [Recording]
}

struct Rating: Codable {
    let value : Double
}

struct MusicBrainzRatingResponse: Codable {
    let rating : Rating
}

func getSongGenre(title : String, album: String, artist : String) async throws -> String {
    let baseURLString = "https://musicbrainz.org/ws/2/release-group/?query=release:"
    let queryString = "\"\(album)\" AND artist:\"\(artist)\""
    let queryParameter = "&fmt=json"
    let encodedQuery = customURLEncode(queryString)
    let initialQueryString = "\(baseURLString)\(encodedQuery)\(queryParameter)"
//    let initialQueryString = "https://musicbrainz.org/ws/2/release-group/?query=release:\"\(album)\" AND artist:\"\(artist)\" &fmt=json"
    var secondQueryString = ""
    
    var genreList = [(name: String, count: Int?)]()
    var SortedGenreList = [(name: String, count: Int?)]()
    
    do {
        let data = try await fetchData(from: initialQueryString)
        let firstResponse = try JSONDecoder().decode(MusicBrainzReleaseResponse.self, from: data)
        
        for release in firstResponse.releaseGroups{
            if release.primaryType == "Album"{
                let firstID = release.id
                secondQueryString = "https://musicbrainz.org/ws/2/release-group/\( firstID)?inc=genres&fmt=json"
                
                let genreData = try await fetchData(from: secondQueryString)
                let genreResponse = try JSONDecoder().decode(MusicBeanzGenreResponse.self, from: genreData)
                
                for genre in genreResponse.genres{
                    genreList.append((name: genre.name, count: genre.count))
                }
                
                SortedGenreList = genreList.sorted{
                    ($0.count ?? 0) > ($1.count ?? 0)
                }
                
                break
            }
        }
    } catch {
        print("Errors: \(error)")
    }
    
    var returnGenre = ""
    if SortedGenreList.isEmpty {
        throw NoGenreError.noGenreReturned("No genre was returned for artist: \(artist) album: \(album) title: \(title)")
    } else {
        returnGenre = SortedGenreList[0].name
    }
    
        return returnGenre
}


func fetchData(from urlPath: String) async throws -> Data {
    guard let url = URL(string: urlPath) else {
        print("Invalid URL")
        throw NSError(domain: "URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)

    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 503 {
        print("Rate limit exceeded, retrying after delay...")
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return try await fetchData(from: urlPath)
    }
    
    // Check for a valid HTTP response
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "HTTPError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
    }
    
    return data
}

func getSongRating(song: SongFile) async{
    // get song id
    let songFileTitle = await song.getTitle()
    
//    let initialQueryString = "https://musicbrainz.org/ws/2/recording/?query=recording:\"\(songFileTitle)\" AND artist:\"\(song.artist)\" AND release:\"\(song.album)\"&fmt=json"

    let baseURLString = "https://musicbrainz.org/ws/2/recording/?query=recording:"
    let queryString = "\"\(songFileTitle)\" AND artist:\"\(song.artist)\" AND release:\"\(song.album)\""
    let queryParameter = "&fmt=json"
    let encodedQuery = customURLEncode(queryString)
    let initialQueryString = "\(baseURLString)\(encodedQuery)\(queryParameter)"
    
    do {
        let recordingData = try await fetchData(from: initialQueryString)
        let response = try JSONDecoder().decode(MusicBrainzRecordingResponse.self, from: recordingData).recordings
        
        if response.isEmpty {
            throw NoSongError.noSongReturned("No song info was found for \(song.artist) - \(song.album) - \(songFileTitle)")
        } else {
            var recordingId = ""
            
            // NEED TO ENSURE THAT WE CHECK ALBUM WHEN WE SEND THE FIRST QUERY and primary type is album
            // ^ add it to the codings at the top
            
            for item in response {
                if normalizeCharacters(in: item.title.lowercased()) == normalizeCharacters(in: songFileTitle.lowercased()){
                    for release in item.releases {
                        if release.title.lowercased() == song.album.lowercased() {
                            recordingId = item.id
                            break
                        }
                    }
                    
                }
            }
            if recordingId != "" {
                let secondQueryString = "https://musicbrainz.org/ws/2/recording/\(recordingId)?inc=ratings&fmt=json"
                let ratingData = try await fetchData(from: secondQueryString)
                let ratingResponse = try JSONDecoder().decode(MusicBrainzRatingResponse.self, from: ratingData).rating
                if song.updateRating(rating: ratingResponse.value){
                    print("song rating updated to \(ratingResponse.value) for song \(songFileTitle)")
                }
            } else {
                throw NoSongError.noSongReturned("No song info was found for \(song.artist) - \(song.album) - \(songFileTitle)")
            }
        }
        } catch {
        print("Errors getting rating for \(song.artist) - \(song.album) - \(songFileTitle) setting rating to zero")
        let complete = song.updateRating(rating: 0.0)
    }
}

// below is used to convert special characters to ASCII equivalents
func normalizeCharacters(in string: String) -> String {
    let replacements: [String: String] = [
        // Apostrophes
        "’": "'",  // Right single quotation mark
        "‘": "'",  // Left single quotation mark
        "´": "'",  // Acute accent
        "`": "'",  // Grave accent

        // Quotation marks
        "“": "\"", // Left double quotation mark
        "”": "\"", // Right double quotation mark
        "„": "\"", // Double low quotation mark
        "«": "\"", // Left-pointing double angle quotation mark
        "»": "\"", // Right-pointing double angle quotation mark

        // Dashes and hyphens
        "–": "-",  // En dash
        "—": "-",  // Em dash
        "‐": "-",  // Hyphen

        // Spaces
        "\u{00A0}": " ", // Non-breaking space

        // Ellipsis
        "…": "..." // Ellipsis
    ]

    var normalizedString = string
    for (original, replacement) in replacements {
        normalizedString = normalizedString.replacingOccurrences(of: original, with: replacement)
    }
    return normalizedString
}

// custom url encoder to handle special characters with music brainz get requests
func customURLEncode(_ string: String) -> String {
    // map of characters to encode
    let replacements: [Character: String] = [
        "+": "%2B",
        "\"": "%22",
        "&": "%26",
        "=": "%3D",
        "(": "%28",
        ")": "%29",
        ":": "%3A",
        "/": "%2F",
        "?": "%3F",
        "#": "%23",
        "@": "%40",
        "[": "%5B",
        "]": "%5D",
        "{": "%7B",
        "}": "%7D",
        "|": "%7C",
        ",": "%2C"
    ]
    
    var allowedCharacters = CharacterSet.urlQueryAllowed
    for character in replacements.keys {
        if let scalar = character.unicodeScalars.first {
            allowedCharacters.remove(scalar)
        }
        
    }

    var encodedString = ""

    for character in string {
        if let replacement = replacements[character] {
            encodedString.append(replacement)
        } else if let scalar = character.unicodeScalars.first, allowedCharacters.contains(scalar) {
            encodedString.append(character)
        } else {
            // Percent-encode any characters not in the allowed set
            let encodedCharacter = character.utf8.map { String(format: "%%%02X", $0) }.joined()
            encodedString.append(encodedCharacter)
        }
    }

    return encodedString
}
