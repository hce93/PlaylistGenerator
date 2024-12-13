//
//  NavigationBarView.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 24/10/2024.
//

import SwiftUI

//struct MainTemplate : View {
//    
//    @State private var selectedPage: String? = "Home" // Track which view is selected
//    
//    var body : some View {
//        NavigationSplitView {
//                   List {
//                       NavigationLink("Home") {
//                           EmptyView()
//                               .navigationTitle("Home")
//                               .tag("Home")
//                       }
//                       NavigationLink("Info") {
//                           EmptyView()
//                               .navigationTitle("Info")
//                               .tag("Info")
//                       }
//                       NavigationLink("Add/Modify Music Folder Location") {
//                           EmptyView()
//                               .navigationTitle("Add/Modify Music Folder Location")
//                               .tag("SetLibrary")
//                       }
//
//                   }
//                   .listStyle(SidebarListStyle())
//                   .navigationTitle("Menu")
//               } detail: {
//                   switch selectedPage {
//                               case "Home":
//                                   ContentView()
//                               case "Info":
//                                   Info()
//                               case "SetLibrary":
//                                   SetLibraryFolder()
//                               default:
//                                   Text("Select an option from the sidebar.")
//                               }
//               }
//
//    }
//}
