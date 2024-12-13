//
//  LoadingOverlay.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 06/12/2024.
//

import SwiftUI

struct LoadingOverlay: View {
    @State var comment: String
    @State var colour: Color
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            colour.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            // Activity indicator
            VStack {
                ProgressView() // Default spinning indicator
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Text("Loading data, please wait...")
                    .foregroundColor(.white)
                    .font(.headline)
                Text(comment)
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
        }
    }
}
