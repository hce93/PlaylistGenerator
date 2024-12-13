//
//  ApplicationTermination.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 23/10/2024.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clear the folder location when the app is terminated
        UserDefaults.standard.removeObject(forKey: "musicFolderLocation")
    }
}
