//
//  SetLibraryFolder.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 22/10/2024.
//

import SwiftUI
import AppKit

struct SetLibraryFolder : View {
    @State private var forgetFolder = false
    @Binding var currentMusicFolder: String
    
    var body : some View {
        
        NavigationStack {
            VStack{
                Text("Set Library Folder Here")
                Button(action: {
                    Task{
                        await selectMusicLibrary()
                    }
                }) {
                    Label("Add Music Library", systemImage: "folder.badge.plus")
                }
                
                if !currentMusicFolder.isEmpty{
                    Text(currentMusicFolder)
                }
                Toggle(isOn : $forgetFolder) {
                    Text("Remove folder from memory when you close the app")
                }

            }
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
//        used continuation to ensure async is adhered to as NSOpenPanel is callback based
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
