//
//  MusicPlayerManager.swift
//  YUIKE-App
//
//  Created by Kuniaki Yui on 2026/06/25.
//

import Foundation
import MediaPlayer
import Combine

class MusicPlayerManager: ObservableObject {
    private let musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying: Bool = false
    @Published var currentTitle: String = "No Song Selected"
    @Published var playbackState: String = "Stopped"
    @Published var currentBPM: Double = 120.0
    
    private let lastSongIDKey = "LastPlayedSongPersistentID"
    private let lastPlaybackTimeKey = "LastPlayedSongPlaybackTime"
    
    // 🔧 ADDED: A temporary flag to ensure we skip to the saved time only once when playback starts
    private var needsTimeToRestore: Bool = false
    
    init() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)
            .sink { [weak self] _ in self?.updatePlaybackState() }
            .store(in: &cancellables)
            
        notificationCenter.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in self?.updateNowPlayingItem() }
            .store(in: &cancellables)
            
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        restoreLastPlayedItem()
        updatePlaybackState()
    }
    
    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
    }
    
    func playOrPause() {
        if musicPlayer.playbackState == .playing {
            saveCurrentPlaybackTime()
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
    }
    
    func stop() {
        saveCurrentPlaybackTime()
        musicPlayer.stop()
    }
    
    func setCollection(_ collection: MPMediaItemCollection) {
        needsTimeToRestore = false
            
        // 🔧 FIX: If the user picked a single song, find its album and queue the whole album
        if collection.items.count == 1, let chosenItem = collection.items.first {
            let albumTitle = chosenItem.albumTitle ?? ""
            let artist = chosenItem.artist ?? ""
            
            // Query the user's library for all songs in this specific album
            let query = MPMediaQuery.albums()
            let albumPredicate = MPMediaPropertyPredicate(value: albumTitle, forProperty: MPMediaItemPropertyAlbumTitle)
            let artistPredicate = MPMediaPropertyPredicate(value: artist, forProperty: MPMediaItemPropertyArtist)
            
            query.addFilterPredicate(albumPredicate)
            if !artist.isEmpty {
                query.addFilterPredicate(artistPredicate)
            }
            
            if let albumItems = query.items, !albumItems.isEmpty {
                // Queue the entire album so iOS knows what to play next
                musicPlayer.setQueue(with: query)
                // Tell the player to start specifically with the song the user tapped
                musicPlayer.nowPlayingItem = chosenItem
            } else {
                // Fallback: If album query fails, just queue the single song
                musicPlayer.setQueue(with: collection)
            }
        } else {
            // If it's already a multi-song playlist, just pass it through directly
            musicPlayer.setQueue(with: collection)
        }
        
        musicPlayer.play()
        updatePlaybackState()
        updateNowPlayingItem()
    }
    
    func saveCurrentPlaybackTime() {
        let currentTime = musicPlayer.currentPlaybackTime
        // Only save valid timestamps (avoid negative or arbitrary massive system numbers)
        if currentTime >= 0 && currentTime < 86400 {
            UserDefaults.standard.set(currentTime, forKey: lastPlaybackTimeKey)
        }
    }
    
    private func updatePlaybackState() {
        isPlaying = (musicPlayer.playbackState == .playing)
        
        // 🔧 FIX: Check if we need to restore the previous playback timestamp when the player starts running
        if musicPlayer.playbackState == .playing && needsTimeToRestore {
            needsTimeToRestore = false // Consume the flag immediately to avoid infinite looping
            let savedTime = UserDefaults.standard.double(forKey: lastPlaybackTimeKey)
            if savedTime > 0 {
                // Apply a tiny 0.1s delay to let the audio hardware stabilize before seeking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.musicPlayer.currentPlaybackTime = savedTime
                }
            }
        }
        
        switch musicPlayer.playbackState {
        case .playing: playbackState = "Playing"
        case .paused: playbackState = "Paused"
        case .stopped: playbackState = "Stopped"
        default: playbackState = "Unknown"
        }
        
        // Continuously save time during updates except when we are waiting to restore
        if !needsTimeToRestore {
            saveCurrentPlaybackTime()
        }
    }
    
    private func updateNowPlayingItem() {
        if let currentItem = musicPlayer.nowPlayingItem {
            let title = currentItem.title ?? "Unknown Title"
            currentTitle = title
            
            let idString = String(currentItem.persistentID)
            UserDefaults.standard.set(idString, forKey: lastSongIDKey)
            
            let bpm = currentItem.beatsPerMinute
            if bpm > 0 {
                currentBPM = Double(bpm)
            } else {
                let hash = abs(title.hashValue)
                let calculatedBPM = 70.0 + Double(hash % 91)
                currentBPM = calculatedBPM
            }
        }
    }
    
    private func restoreLastPlayedItem() {
        guard let savedIDString = UserDefaults.standard.string(forKey: lastSongIDKey),
              let savedID = UInt64(savedIDString) else {
            currentTitle = "No Song Selected"
            currentBPM = 120.0
            return
        }
        
        let propertyPredicate = MPMediaPropertyPredicate(value: savedID, forProperty: MPMediaItemPropertyPersistentID)
        let query = MPMediaQuery()
        query.addFilterPredicate(propertyPredicate)
        
        if let items = query.items, let lastItem = items.first {
            let collection = MPMediaItemCollection(items: [lastItem])
            musicPlayer.setQueue(with: collection)
            
            // 🔧 FIX: Instead of setting time now, turn on the flag.
            // We will jump to the saved time the moment the user taps "Play".
            let savedTime = UserDefaults.standard.double(forKey: lastPlaybackTimeKey)
            if savedTime > 0 {
                needsTimeToRestore = true
            }
            
            let title = lastItem.title ?? "Unknown Title"
            currentTitle = title
            
            let bpm = lastItem.beatsPerMinute
            if bpm > 0 {
                currentBPM = Double(bpm)
            } else {
                let hash = abs(title.hashValue)
                let calculatedBPM = 70.0 + Double(hash % 91)
                currentBPM = calculatedBPM
            }
        } else {
            currentTitle = "No Song Selected"
            currentBPM = 120.0
        }
    }
}
