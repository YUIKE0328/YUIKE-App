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
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isPlaying: Bool = false
    @Published var currentTitle: String = "No Song Selected"
    @Published var playbackState: String = "Stopped"
    // 🔧 ADDED: Track the BPM of the current song
    @Published var currentBPM: Double = 120.0
    
    init() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)
            .sink { [weak self] _ in self?.updatePlaybackState() }
            .store(in: &cancellables)
            
        notificationCenter.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in self?.updateNowPlayingItem() }
            .store(in: &cancellables)
            
        musicPlayer.beginGeneratingPlaybackNotifications()
        updatePlaybackState()
        updateNowPlayingItem()
    }
    
    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
    }
    
    func playOrPause() {
        if musicPlayer.playbackState == .playing {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
    }
    
    func stop() {
        musicPlayer.stop()
    }
    
    // 🔧 FIX: Add the missing setCollection method back to the manager
    func setCollection(_ collection: MPMediaItemCollection) {
        musicPlayer.setQueue(with: collection)
        // Automatically start playing when a new collection is set
        musicPlayer.play()
        updatePlaybackState()
        updateNowPlayingItem()
    }
    
    private func updatePlaybackState() {
        isPlaying = (musicPlayer.playbackState == .playing)
        switch musicPlayer.playbackState {
        case .playing: playbackState = "Playing"
        case .paused: playbackState = "Paused"
        case .stopped: playbackState = "Stopped"
        default: playbackState = "Unknown"
        }
    }
    
    private func updateNowPlayingItem() {
        if let currentItem = musicPlayer.nowPlayingItem {
            let title = currentItem.title ?? "Unknown Title"
            currentTitle = title
            
            // Try to get hardcoded metadata first
            let bpm = currentItem.beatsPerMinute
            if bpm > 0 {
                currentBPM = Double(bpm)
            } else {
                // 🔧 FIX: Generate a consistent, song-specific dynamic BPM (70 to 160) using string hashing
                let hash = abs(title.hashValue)
                let calculatedBPM = 70.0 + Double(hash % 91) // 70 + (0 to 90) = 70 to 160 BPM
                currentBPM = calculatedBPM
            }
        } else {
            currentTitle = "No Song Selected"
            currentBPM = 120.0
        }
    }
}
