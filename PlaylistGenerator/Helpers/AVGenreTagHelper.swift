//
//  ID3TagHelper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 30/10/2024.
//
import SwiftUI
import Foundation
import ID3TagEditor
import AVFoundation

enum FileTypeError: Error {
    case unsupportedFileType(String)
}

func updateAVGenreTags(fileURLs: [URL]) async -> [String]{
    var errorList = [String]()
    let fileManager = FileManager.default
    var genreDict : [String : [String:String]] = [:]
    
    for url in fileURLs{
        // Load the audio file as an AVAsset
        let asset = AVURLAsset(url: url)
        
        var artist: String?
        var album: String?
        
        do{
            var existingMetadata = try await asset.load(.metadata)
            
            for item in existingMetadata{
                if let key = item.commonKey?.rawValue {
                    switch key {
                    case "artist":
                        if artist == nil{
                            artist = try await item.load(.stringValue)
                        }
                    case "albumName":
                        if album == nil{
                            album = try await item.load(.stringValue)
                        }
                    default:
                        break
                    }
                    
                }
            }
            
            // if artist, album or title isnt held in the metadata we can use the file structure as a fallback
            if (artist == nil) || (album == nil){
                let pathComponents = url.pathComponents
                if artist == nil{
                    artist = pathComponents[pathComponents.count - 3]
                }
                if album == nil{
                    album = pathComponents[pathComponents.count - 2]
                }

            }
            
            if (artist != nil) && (album != nil){
                // check if the genre is held within the dictionary so we dont have to send repeat requests
                var suggestedGenre: String
                if var artistDict = genreDict[artist!] {
                    if let albumGenre = artistDict[album!] {
                        suggestedGenre = albumGenre
                    } else {
                        suggestedGenre = try await getSongGenre(album: album!, artist: artist!)
                        artistDict[album!] = suggestedGenre
                        genreDict[artist!] = artistDict
                    }
                } else {
                    suggestedGenre = try await getSongGenre(album: album!, artist: artist!)
                    genreDict[artist!] = [album!: suggestedGenre]
                }
                
                if suggestedGenre == ""{
                    errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - No Genre Found")
                    continue
                }
                
                // Create a new AVMutableMetadataItem for the genre
                let metadataGenre = AVMutableMetadataItem()
                metadataGenre.key = AVMetadataKey.iTunesMetadataKeyUserGenre.rawValue as NSString // Convert the enum to raw value string
                metadataGenre.keySpace = .iTunes
                metadataGenre.value = suggestedGenre.capitalized as NSString
                
                // Remove the old genre metadata if it exists
                existingMetadata.removeAll { item in
                                    (item.key as? String) == AVMetadataKey.iTunesMetadataKeyUserGenre.rawValue
                                }
                
                // Add the updated genre metadata
                existingMetadata.append(metadataGenre)

                // Create an AVAssetExportSession to save the updated metadata
                let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
                exportSession?.outputFileType = try fileTypeForURL(url)

                // Define the output URL (overwrite the original file or create a new one)
                let tempURL = url.deletingLastPathComponent().appendingPathComponent("Updated_" + url.lastPathComponent)
                exportSession?.outputURL = tempURL
                // Assign the updated metadata to the export session
                exportSession?.metadata = existingMetadata
                
                // Export the file with the updated genre metadata
                exportSession?.exportAsynchronously {
                    if let error = exportSession?.error {
                        print("Error updating genre: \(error)")
                        errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Creating File Error")
                    } else {
                        print("Genre updated successfully and metadata preserved!")
                        do {
                            try fileManager.replaceItemAt(url, withItemAt: tempURL)
                        } catch let fileError {
                            errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - File Replacement Error")
                        }
                    }
                }
            } else {
                errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - "))")
            }
            
        } catch {
            errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - "))")
            print("Error loading metadata: \(error)")
        }
    }
    return errorList
}

func fileTypeForURL(_ url: URL) throws -> AVFileType? {
    switch url.pathExtension.lowercased() {
    case "aif", "aiff":
        return .aiff
    case "m4a":
        return .m4a
    case "mp4":
        return .mp4
    case "caf":
        return .caf
    default:
        throw FileTypeError.unsupportedFileType("Unsupported file type: \(url.pathExtension.lowercased())")
    }
}
 
func getNonMp3GenreTags(url: URL) async -> [String : [String]] {
    var errorList = [String]()
    var genreArray = [String]()
    do {
        let asset = AVURLAsset(url: url)
        let metadata = try await asset.load(.metadata)
        var foundGenre = false
        for item in metadata {
            if let key = item.identifier?.rawValue {
                // Check if the key matches the custom genre identifier "itsk/%A9gen"
                if let keyString = key as? String {
                    if keyString == "itsk/%A9gen" {
                        if let genre = try await item.load(.value) as? String {
                            genreArray = genre.components(separatedBy: "; ").map { $0.capitalized }
                            foundGenre = true
                            break
                        }
                    }
                }
            }
        }
        // if genre isn't found through AVURLAsset method then use mdls method
        if !foundGenre {
            if let genre = getGenreFromFile(url: url) {
                genreArray = genre.components(separatedBy: "; ").map { $0.capitalized }
                foundGenre = true
            }
        }
        if !foundGenre{
            errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Find Genre Error")
        }
    } catch {
        print("Error finding genre for \(url.pathComponents.suffix(3).joined(separator: " - ")): \(error)")
        errorList.append("\(url.pathComponents.suffix(3).joined(separator: " - ")) - Find Genre Error")
    }
    return ["genre" : genreArray, "errors" : errorList]
}

// below ues mdls (spotlight metadata) methods
// this is a fallback for non-mp3 files where AVURLAsset metadata does not find a genre
    // this is often the case for older music files (for examples cd's ripped pre c.2010)
func getGenreFromFile(url: URL) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
    process.arguments = [url.path]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    do {
        try process.run()
    } catch {
        print("Failed to run mdls: \(error)")
        return nil
    }
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        let lines = output.split(separator: "\n")
        for line in lines {
            if line.contains("kMDItemMusicalGenre") {
                // Extract and clean up the genre value
                if let genre = line.split(separator: "=").last?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    return genre.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                }
            }
        }
    }
    return nil
}

func getNonMp3Title(url: URL) -> String {
    let asset = AVURLAsset(url: url)

    if let title = asset.commonMetadata.first(where: { $0.commonKey?.rawValue == "title" })?.stringValue {
        return title
    } else {
        return ""
    }
}
