//
//  Home.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 24/10/2024.
//

import SwiftUI

struct Home : View {
    @State private var forgetFolder = false
    @Binding var currentMusicFolder: String
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                        .frame(height: geometry.size.height * 0.125) // Top margin
                    
                    VStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(40)
                            .frame(width: 500, height: 200)
                            .shadow(color: Color.black, radius: 10, x: 0, y: 0)
                        Spacer()
                            .frame(height: 30)
                        
                        VStack(spacing: 10) {
                            
                            Text("""
                                Welcome to the Playlist Generator!
                                For info on how to use the app please visit the info page
                            """)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                            
                            
                            if !currentMusicFolder.isEmpty {
                                VStack(spacing: 10) {
                                    Text("Your current Music Folder is set to: ")
                                    Text(currentMusicFolder)
                                        .italic(true)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                            VStack(spacing: 10) {
                                if currentMusicFolder.isEmpty {
                                    Text("Set your music library location here")
                                }
                                Button(action: {
                                    Task {
                                        await selectMusicLibrary()
                                    }
                                }) {
                                    if currentMusicFolder.isEmpty {
                                        Text("Add Music Library")
                                    } else {
                                        Text("Update Music Library")
                                    }
                                }
//                                
//                                Toggle(isOn: $forgetFolder) {
//                                    Text("Remove folder from memory when you close the app")
//                                }
                            }
                        }

                    }
                    .frame(height: geometry.size.height * 0.75)                    
                    Spacer()
                        .frame(height: geometry.size.height * 0.125) // Bottom margin
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                currentMusicFolder = getMusicFolderLocation()
            }
            .onAppear {
                currentMusicFolder = getMusicFolderLocation()
            }
            .padding(10)
        }
    }
    
    func selectMusicLibrary() async {
        
        let url = await openPanelAndReturnPath()
        saveMusicFolderLocation(url, persistPermissions: !forgetFolder)
        
        if !url.isEmpty {
            currentMusicFolder = url
        }
    }
    
    func openPanelAndReturnPath() async -> String {
        // Continuation used to ensure async is adhered to as NSOpenPanel is callback based
        return await withCheckedContinuation{ continuation in
            let panel = NSOpenPanel()
            panel.title = "Choose a folder"
            panel.message = "Select the folder for music library access"
            panel.prompt = "Select Folder"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = true
            
            panel.begin { response in
                if response == .OK, let url = panel.urls.first {
                    continuation.resume(returning: url.path)
                } else {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
}
