# Playlist Generator

A macOS app to update genre tags in your music library and create personalized playlists.

## Features
- Automatically fetch genre tags using the Music Brainz API.
- Update genres by artist, album, or individual song.
- Create custom playlists based on your favorite artists, albums, and/or genres.

## How To Use
Firstly, the user will need to select their music library on the home page (landing screen). Once this is done the user can use the following features of the app.

###Genre Updater: 
Within the **"Update Genres"** tab you are able to update genres in your music library by artist, whole albums or specific songs. To do so you can switch between the two "Artists" and "Albums" tabs.

*Note, you will only be able to access this tab once your muis clibrary location is set*

**Where do we get the genres from?** 

For every song you want to update the genre for we will use the **Music Brainz API** to get the genre tags by the song's album. We will then chose the most popular genre (using Music Brainz's own popularity score) and update the genre using that.

**How to update your song genres** 
In the "Artists" tab you will see a list of all the artists in your library. Here you can select as many or as little artists as you want, you can also use the search bar at the top to help you easily find artists. Once you have found the artists you want to update the genres just hit submit and the app will do the rest of the work. The app will cycle through every song for that artists you checked and update the genres. 
In the "Album" tab you can select a number of albums and the right hand table will populate with all the songs for that album. By default all of these songs will be selected. However, you are able to uncheck as many or as little songs as you like. Once you've finalised the list. All the checked songs will then have their genres updated.

![Genre Tab](PlaylistGenerator/Assets.xcassets/genreScreenshot3.imageset/genreScreenshot1.png)

