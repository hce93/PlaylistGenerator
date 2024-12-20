//
//  ID3TagHelper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 14/11/2024.
//

import SwiftUI
import Foundation
import ID3TagEditor

enum InvalidGenreError: Error {
    case noGenreFoundError(String)
}
enum BuilderError: Error {
    case unableToCreateBuilder(String)
}
enum ID3TagError: Error {
    case invalidFrameType(expected: String, found: String)
}

func updateID3GenreTags(fileURLs: [URL]) async -> [String]{
    var errorList = [String]()
    var genreDict : [String : [String:String]] = [:]
    for url in fileURLs {
 
        let tagEditor = ID3TagEditor()
        let musicFolder = getMusicFolderLocation()
        // create a temp location to store the file
        // this will be used to replace the existing file
        let tempLocation = musicFolder + "/tempFile.mp3"
        let tempURL = URL(fileURLWithPath: tempLocation)
        
        do {
            if let tag = try tagEditor.read(from: url.path){
                let artistFrame = tag.frames[.artist] as? ID3FrameWithStringContent
                let albumFrame = tag.frames[.album] as? ID3FrameWithStringContent
                
                let artist = (artistFrame?.content ?? "") as String
                let album = (albumFrame?.content ?? "") as String
                
                var builder = ID32v3TagBuilder()
                do {
                    builder = try await generateBuilder(tag: tag)
                } catch {
                    errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Builder Error")
                    continue
                }
                
                var suggestedGenre: String
                // check if the genre is held within the dictionary so we dont have to send repeat requests
                if var artistDict = genreDict[artist] {
                    if let albumGenre = artistDict[album] {
                        suggestedGenre = albumGenre
                    } else {
                        suggestedGenre = try await getSongGenre(album: album, artist: artist)
                        artistDict[album] = suggestedGenre
                        genreDict[artist] = artistDict
                    }
                } else {
                    suggestedGenre = try await getSongGenre(album: album, artist: artist)
                    genreDict[artist] = [album: suggestedGenre]
                }
                
                if suggestedGenre == "" {
                    errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - No Genre Found")
                    continue
                } else {
                    // check if an id3 tag exists for the suggested genre
                    // if not create a custom genre with the string
                    if let validGenre = getValidGenre(suggestedGenre: suggestedGenre) {
                        builder = builder.genre(frame: validGenre)
                    } else {
                        // customGenre will fallback to the given description if the genre is nil
                        let customGenre = ID3FrameGenre(genre: nil, description: suggestedGenre.capitalized)
                        builder = builder.genre(frame: customGenre)
                    }
                    
                    try tagEditor.write(tag: builder.build(), to: url.path, andSaveTo: tempURL.path)
                    let fileManager = FileManager.default
                    let newURL = try fileManager.replaceItemAt(url, withItemAt: tempURL)
                    if newURL == nil{
                        print("Error replacing file for \(url.pathComponents.suffix(3).joined(separator: " - "))")
                        errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - File update failed")
                    }
                }
                

            }
        } catch{
            print("Error Updating Genre for \(url.pathComponents.suffix(3).joined(separator: " - ")): \(error)")
            errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - "))")
        }
    }
    return errorList
}

//function to help build a new file to replace existing one with
//do this so we don't get a cross-device link error when trying to modify an existing file
func generateBuilder(tag: ID3Tag) async throws -> ID32v3TagBuilder {
    var builder = ID32v3TagBuilder()
    do {
        try await populateBuilder(tag: tag, builder: &builder)
    } catch {
        print("Error creating ID3 Tag: \(error)")
        throw error
    }
    return builder
}

func generateGenreTag(string: String) -> ID3Genre? {
    let regexValue = try! NSRegularExpression(pattern: "\\s", options: [])
    let cleanedString = regexValue.stringByReplacingMatches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count), withTemplate: "").lowercased()
    
//    check if genre tag already exists
    if isValidEnumCase(string: cleanedString){
        let enumValue = ID3Genre.allCases.filter { String(describing: $0).lowercased() == cleanedString }[0]
        return enumValue
    }
    return nil
}

func getValidGenre(suggestedGenre: String) -> ID3FrameGenre?{

    if let genre = generateGenreTag(string: suggestedGenre){
        let genreFrame = ID3FrameGenre(genre: genre, description: String(describing: genre))
        return genreFrame
    }
    return nil
}
    
func isValidEnumCase(string: String) -> Bool {
    return ID3Genre.self.allCases.contains { String(describing: $0).lowercased() == string }
}


func populateBuilder(tag: ID3Tag, builder: inout ID32v3TagBuilder) async throws {
    do {
        for (key, frame) in tag.frames {            
            switch key {
            case .album:
                guard let albumFrame = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.album(frame: albumFrame)
            case .albumArtist:
                guard let albumArtistFrame = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.albumArtist(frame: albumArtistFrame)
            case .artist:
                guard let artistFrame = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.artist(frame: artistFrame)
            case .attachedPicture:
                guard let attachedPicture = frame as? ID3FrameAttachedPicture else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameAttachedPicture", found: "\(type(of: frame)) for frame \(key)")
                }
                let pictureType = attachedPicture.type
                builder = builder.attachedPicture(pictureType: pictureType, frame: attachedPicture)
            case .beatsPerMinute:
                guard let beatsPerMinute = frame as? ID3FrameWithIntegerContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithIntegerCount", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.beatsPerMinute(frame: beatsPerMinute)
            case .comment:
                guard let comment = frame as? ID3FrameWithLocalizedContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameContentLanguage", found: "\(type(of: frame)) for frame \(key)")
                }
                let language = comment.language
                builder = builder.comment(language: language, frame: comment)
            case .composer:
                guard let composer = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.composer(frame: composer)
            case .conductor:
                guard let conductor = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.conductor(frame: conductor)
            case .contentGrouping:
                guard let contentGrouping = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.contentGrouping(frame: contentGrouping)
            case .copyright:
                guard let copyright = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.copyright(frame: copyright)
            case .discPosition:
                guard let discPosition = frame as? ID3FramePartOfTotal else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FramePartOfTotal", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.discPosition(frame: discPosition)
            case .encodedBy:
                guard let encodedBy = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.encodedBy(frame: encodedBy)
            case .encoderSettings:
                guard let encoderSettings = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.encoderSettings(frame: encoderSettings)
            case .fileOwner:
                guard let fileOwner = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.fileOwner(frame: fileOwner)
            case .genre:
                guard let genre = frame as? ID3FrameGenre else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameGenre", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.genre(frame: genre)
            case .iTunesGrouping:
                guard let iTunesGrouping = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesGrouping(frame: iTunesGrouping)
            case .iTunesMovementCount:
                guard let iTunesMovementCount = frame as? ID3FrameWithIntegerContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithIntegerContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesMovementCount(frame: iTunesMovementCount)
            case .iTunesMovementIndex:
                guard let iTunesMovementIndex = frame as? ID3FrameWithIntegerContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithIntegerContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesMovementIndex(frame: iTunesMovementIndex)
            case .iTunesMovementName:
                guard let iTunesMovementName = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesMovementName(frame: iTunesMovementName)
            case .iTunesPodcastCategory:
                guard let iTunesPodcastCategory = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesPodcastCategory(frame: iTunesPodcastCategory)
            case .iTunesPodcastDescription:
                guard let iTunesPodcastDescription = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesPodcastDescription(frame: iTunesPodcastDescription)
            case .iTunesPodcastID:
                guard let iTunesPodcastID = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesPodcastID(frame: iTunesPodcastID)
            case .iTunesPodcastKeywords:
                guard let iTunesPodcastKeywords = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.iTunesPodcastKeywords(frame: iTunesPodcastKeywords)
            case .lengthInMilliseconds:
                guard let lengthInMilliseconds = frame as? ID3FrameWithIntegerContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithIntegerContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.lengthInMilliseconds(frame: lengthInMilliseconds)
            case .lyricist:
                guard let lyricist = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.lyricist(frame: lyricist)
            case .mixArtist:
                guard let mixArtist = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.mixArtist(frame: mixArtist)
            case .originalFilename:
                guard let originalFilename = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.originalFilename(frame: originalFilename)
            case .publisher:
                guard let publisher = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.publisher(frame: publisher)
            case .recordingDayMonth:
                guard let recordingDayMonth = frame as? ID3FrameRecordingDayMonth else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameRecordingDayMonth", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.recordingDayMonth(frame: recordingDayMonth)
            case .recordingHourMinute:
                guard let recordingHourMinute = frame as? ID3FrameRecordingHourMinute else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameRecordingHourMinute", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.recordingHourMinute(frame: recordingHourMinute)
            case .recordingYear:
                guard let recordingYear = frame as? ID3FrameWithIntegerContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithIntegerContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.recordingYear(frame: recordingYear)
            case .sizeInBytes:
                guard let sizeInBytes = frame as?ID3FrameWithIntegerContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithIntegerContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.sizeInBytes(frame: sizeInBytes)
            case .subtitle:
                guard let subtitle = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.subtitle(frame: subtitle)
            case .title:
                guard let title = frame as? ID3FrameWithStringContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithStringContent", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.title(frame: title)
            case .trackPosition:
                guard let trackPosition = frame as? ID3FramePartOfTotal else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FramePartOfTotal", found: "\(type(of: frame)) for frame \(key)")
                }
                builder = builder.trackPosition(frame: trackPosition)
            case .unsynchronizedLyrics:
                guard let unsynchronizedLyrics = frame as? ID3FrameWithLocalizedContent else {
                    throw ID3TagError.invalidFrameType(expected: "ID3FrameWithLocalizedContent", found: "\(type(of: frame)) for frame \(key)")
                }
                let language = unsynchronizedLyrics.language
                builder = builder.unsynchronisedLyrics(language: language, frame: unsynchronizedLyrics)
            default:
                break
            }
        }
        
    } catch {
        print("Error: \(error)")
        throw error
    }
}

func getMp3GenreTags(url: URL) async -> [String : [String]] {
    var genreArray = [String]()
    var errorList = [String]()
    let tagEditor = ID3TagEditor()
    do {
        let id3Tag = try tagEditor.read(from: url.path)
        if id3Tag != nil{
            if let genereFrame = id3Tag?.frames[.genre] as? ID3FrameGenre {
                if let text = genereFrame.description{
                    if text != "" {
                        genreArray = text.components(separatedBy: "; ").map{ $0.capitalized }
                    } else {
                        errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Find Genre Error")
                    }
                    
                }else {
                    errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Find Genre Error")
                }
            }
        }
    } catch {
        errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Find Genre Error")
    }
    return ["genre" : genreArray, "errors" : errorList]
}

func getMp3Title(url: URL) async throws -> String {
    let id3TagEditor = ID3TagEditor()
    do {
        let id3Tag = try id3TagEditor.read(from: url.path)
        if let title = id3Tag?.frames[.title] as? ID3FrameWithStringContent {
            return title.content
        } else {
            print("Title not found.")
        }
    } catch {
        print("Error reading ID3 tag: \(error)")
    }
    return ""
}
