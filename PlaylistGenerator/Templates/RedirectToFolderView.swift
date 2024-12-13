//
//  RedirectToSelectFolder.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 24/10/2024.
//

//import SwiftUI
//
//struct RedirectToFolderView : View {
//    @State var currentMusicFolder: String
//    
//    var body: some View {
//            List{
//                if currentMusicFolder=="" {
//                    Text("Plase set your music folder location to create playlists using the below link")
//                    NavigationLink("Set Folder"){
//                        SetLibraryFolder()
//                            .navigationTitle("Set Music Library")
//                    }
//                }
//            }
//            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
//                // Listen for UserDefaults changes
//                currentMusicFolder = getMusicFolderLocation()
//            }
//            .onAppear {
//                currentMusicFolder = getMusicFolderLocation()
//            }
//        
//    }
//}
