//
//  UpdateGenre.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 22/10/2024.
//

import SwiftUI
import AVFoundation
import ID3TagEditor
import Foundation

struct UpdateGenre : View {
//    @State private var tabViewCoordinators: [String: MusicFolderTabView.Coordinator] = [:]
    @ObservedObject var artistCoordinator : MusicFolderTabView.Coordinator
    @ObservedObject var albumCoordinator : MusicFolderTabView.Coordinator
    @ObservedObject var songCoordinator : SongTabView.SongCoordinator
    
    let tabOptions = ["Artists", "Albums"]

    var body : some View {
        NavigationStack
        {
            TabHandler(songCoordinator : songCoordinator, artistCoordinator : artistCoordinator, albumCoordinator : albumCoordinator)
        }
    }
}
