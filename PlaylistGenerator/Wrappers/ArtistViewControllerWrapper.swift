//
//  ArtistViewControllerWrapper.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 04/11/2024.
//

import SwiftUI

struct ArtistTableView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> ArtistViewController {
        return ArtistViewController() // Use your existing ViewController
    }

    func updateNSViewController(_ nsViewController: ArtistViewController, context: Context) {
        // Update logic if needed
    }
}
