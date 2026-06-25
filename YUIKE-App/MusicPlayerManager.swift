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
    private var musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    @Published var currentTitle: String = "No Song Selected"
    @Published var playbackState: String = "Stopped"
    @Published var isPlaying: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe playback state changes (Play/Pause from lock screen or app)
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)
            .sink { [weak self] _ in
                self?.updatePlaybackState()
            }
            .store(in: &cancellables)
            
        // Observe song changes
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in
                self?.updateNowPlaying()
            }
            .store(in: &cancellables)
            
        musicPlayer.beginGeneratingPlaybackNotifications()
        setupRemoteCommandCenter()
        updatePlaybackState()
        updateNowPlaying()
    }
    
    deinit {
        musicPlayer.endGeneratingPlaybackNotifications()
    }
    
    // Setup Remote Command Center (Lock Screen / Control Center Actions)
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Handle Play Command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.musicPlayer.play()
            return .success
        }
        
        // Handle Pause Command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.musicPlayer.pause()
            return .success
        }
        
        // Handle Toggle Play/Pause Command (e.g., Earphones button)
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.playOrPause()
            return .success
        }
    }
    
    func setCollection(_ collection: MPMediaItemCollection) {
        musicPlayer.setQueue(with: collection)
        musicPlayer.play()
        updatePlaybackState()
        updateNowPlaying()
    }
    
    func playOrPause() {
        if musicPlayer.playbackState == .playing {
            musicPlayer.pause()
        } else {
            musicPlayer.play()
        }
        updatePlaybackState()
    }
    
    private func updatePlaybackState() {
        DispatchQueue.main.async {
            if self.musicPlayer.playbackState == .playing {
                self.isPlaying = true
                self.playbackState = "Playing"
            } else if self.musicPlayer.playbackState == .paused {
                self.isPlaying = false
                self.playbackState = "Paused"
            } else {
                self.isPlaying = false
                self.playbackState = "Stopped"
            }
        }
    }
    
    private func updateNowPlaying() {
        DispatchQueue.main.async {
            if let nowPlayingItem = self.musicPlayer.nowPlayingItem {
                self.currentTitle = nowPlayingItem.title ?? "Unknown Title"
            } else {
                self.currentTitle = "Not Playing"
            }
        }
    }
    
    func stop() {
        musicPlayer.stop()
        updatePlaybackState()
    }
}
