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
        NotificationCenter.default.publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
            .sink { [weak self] _ in
                self?.updateNowPlaying()
            }
            .store(in: &cancellables)
            
        musicPlayer.beginGeneratingPlaybackNotifications()
        updateNowPlaying()
    }
    
    func setCollection(_ collection: MPMediaItemCollection) {
        musicPlayer.setQueue(with: collection)
        musicPlayer.play()
        isPlaying = true
        playbackState = "Playing"
        updateNowPlaying()
    }
    
    func playOrPause() {
        if musicPlayer.playbackState == .playing {
            musicPlayer.pause()
            isPlaying = false
            playbackState = "Paused"
        } else {
            musicPlayer.play()
            isPlaying = true
            playbackState = "Playing"
        }
    }
    
    private func updateNowPlaying() {
        if let nowPlayingItem = musicPlayer.nowPlayingItem {
            currentTitle = nowPlayingItem.title ?? "Unknown Title"
        } else {
            currentTitle = "Not Playing"
        }
    }
}
