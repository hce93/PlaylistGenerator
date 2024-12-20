//
//  Info.swift
//  PlaylistGenerator
//
//  Created by Henry Evison on 22/10/2024.
//

import SwiftUI

struct Info : View {
    var body : some View {
        GeometryReader{ geometry in
            
            ScrollView{
                
                VStack{
                    
                    Spacer()
                        .frame(height: 20)
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(40)
                        .frame(width: 300, height: 120)
                        .shadow(color: Color.black, radius: 10, x: 0, y: 0)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    Text("""
                    This app is built to update genre tags for your own music library and also generate playlists based off selected artists, albums or genres within your library. You can then save this playlist to your computers Apple Music app and listen from there. Below is a brief guide on using the app:
                    """)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 800)
                        .frame(width: geometry.size.width*0.7)
                        .padding(.bottom, 10)
                        
                    Spacer()
                        .frame(height: 10)
                    
                    Text("Setting Your Music Library")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                    Text("""
                    In order to use the app your firstly need to set your music library folder location which will allow the app to read al of your songs/files within this library. You can do this in the "Home" page by selecting the button at the bottom labelled "Add Music Library". This will open a window where you can select your music library location. 
                    
                    Please note, in order for the app to work it expects your library to be orgainsed by artist folders then album folders then song files. Once you have set your music library location the app will then get to work loading all of the relevant information for the app to work. 
                    
                    *Note, the "Update Genres" and "Create New Playlists" tab will sometimes show loading screens initially if you select these after setting your library. This is because it can take a bit of time to load all the information (especially genre data) from your music library. Especially if your library is large.*
                    """)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 800)
                        .frame(width: geometry.size.width*0.7)
                        .padding(.bottom, 10)
                    
                    Spacer()
                        .frame(height: 10)
                        
                    Text("Updating Genres")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                        
                    Text("""
                    Within the "Update Genres" tab you are able to update genres in your music library by artist, whole albums or specific songs. To do so you can switch between the two "Artists" and "Albums" tabs.
                    
                    *Note, you will only be able to access this tab once your muis clibrary location is set*
                    
                    ***Where do we get the genres from?*** 
                    
                    For every song you want to update the genre for we will use the Music Brainz API to get the genre tags by the song's album. We will then chose the most popular genre (using Music Brainz's own popularity score) and update the genre using that.
                    
                    ***How to update your song genres*** 
                    
                    In the "Artists" tab you will see a list of all the artists in your library. Here you can select as many or as little artists as you want, you can also use the search bar at the top to help you easily find artists. Once you have found the artists you want to update the genres just hit submit and the app will do the rest of the work. The app will cycle through every song for that artists you checked and update the genres. Below shows a screenshot of the "Artists" tab where you can see an example list of artists to chose from to update genres for. 
                    
                    """)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 800)
                        .frame(width: geometry.size.width*0.7)
                        
                    Image("genreScreenshot1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 700)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("""
                    Below you can see a screenshot for the "Albums" tab. Here you can see an example list of albums you can chose from to update the genres. When you select an album the right hand table will populate with all the songs for that album. By default all of these songs will be selected. However, you are able to uncheck as many or as little songs as you like. Once you've finalised the list. All the checked songs will then have their genres updated.
                    """)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 800)
                    .frame(width: geometry.size.width*0.7)
                    
                    Image("genreScreenshot2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 700)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("""
                    Note, if there are any errors updating an artists genres you will be presented with an alert showing all of the songs where issues occured. Reasons for this could be typos on artist/album/song names or the artist/album not included within the Music Brainz database. An example alert is below. Here Music Brainz does not recognise the artist "30 Seconds To Mars" because they have the artist name as "Thirty Seconds To Mars" in their database.
                    """)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 800)
                    .frame(width: geometry.size.width*0.7)
                    
                    Image("genreScreenshot3")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 700)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("Creating Playlists")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                    
                    Text("""
                    The second feature of this app is to generate playlists. You can do this in the "Create New Playlists" tab. Here you will find 3 tables which will list out all of the artists and albums in your library as well as all the genre's across every song in your library.
                    
                    *Note, you will only be able to access this tab once your muis clibrary location is set*
                    
                    If you select specific artists/genres/albums this will ensure songs from this artist/genre/album will be added to the playlist. The songs that make up the artist/album/genre selection you make will be randomised and then the playlist generator will select one song from each artist/album/genre according to their rating in the Music Brainz's database (which uses user review scores). This will then loop until the playlist is populated.
                    
                    Below the tables you will find a "% in playlist" selector. Here you can dictate the % that you want the artists, albums and genres to take up within the playlist. As soon as you make your initial selection by default that catageory will assume 100% of the playlist. Once you make selections from other categories you will then be able to adjust the selectors to suit the playlist you want to create. 
                    
                    Below the % selectors you will find a drop down allowing you to dictate how large you want the playlist to be. Note, if you select a number which is larger then the songs available in the artist/album/genre selections you have made, all the available songs will be added to the playlist. 
                    
                    Finally, once you are happy with your selections you simply need to hit "Generate Playlist" and then a playlist will be generated for you.
                    """)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 800)
                    .frame(width: geometry.size.width*0.7)
                    
                    Image("playlistScreenshot1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 700)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("""
                    Once you have selected "Generate Playlist", after a short delay (length of which will depend on the number of selections made), the bottom table will then be populated with the generated playlist. You can now browse the songs that have been selected to see if you like it. If you are happy with the playlist you can give it a name in the text field above the table and then hit "Save Playlist" which will then add it to your Apple Music app. 
                    
                    If you would like to adjust the suggested playlist you can also do that! To not include songs in a playlist simply uncheck the checkboxes on the right side of the playlist table. If unchecked the songs will nnot form part of the playlist when you submit it. You can also add your own choice of songs if you would like too. To do this just select the "Add Song To Playlist" button. This will open up a new window where you can navigate to specific songs you would like to add. You can add as many or as little songs as you like. Once happy just hit the "Save Playlist" button.
                    """)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: 800)
                        .frame(width: geometry.size.width*0.7)
                    
                    Image("playlistScreenshot2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 700)
                    
                    Spacer()
                        .frame(height: 10)
                    
                    Text("*Note, this app is built for macOS*")
                    
                    Spacer()
                        .frame(height: 40)
                    
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
