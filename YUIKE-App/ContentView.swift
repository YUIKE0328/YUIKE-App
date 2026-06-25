//
//  ContentView.swift
//  YUIKE-App
//
//  Created by Kuniaki Yui on 2026/06/25.
//

import SwiftUI
import MediaPlayer

struct ContentView: View {
    @StateObject private var playerManager = MusicPlayerManager()
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    @State private var showPicker = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Puppet Visualizer")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                PuppetView(isPlaying: playerManager.isPlaying, bassLevel: audioAnalyzer.bassLevel)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(playerManager.currentTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text(playerManager.playbackState)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    // Optional: Debug text to see current synced BPM on screen
                    Text("BPM: \(Int(playerManager.currentBPM))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                HStack(spacing: 30) {
                    Button(action: {
                        showPicker = true
                    }) {
                        Label("Select Song", systemImage: "music.note.list")
                            .font(.headline)
                            .padding()
                            .frame(width: 160)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        playerManager.playOrPause()
                    }) {
                        Label(playerManager.isPlaying ? "Pause" : "Play", systemImage: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .padding()
                            .frame(width: 140)
                            .background(playerManager.isPlaying ? Color.orange : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showPicker) {
            MediaPickerRepresentation(playerManager: playerManager)
        }
        // Handle playback toggle with specific BPM data passed in
        .onChange(of: playerManager.isPlaying) { oldState, isPlaying in
            if isPlaying {
                audioAnalyzer.startMonitoring(bpm: playerManager.currentBPM)
            } else {
                audioAnalyzer.stopMonitoring()
            }
        }
        // 🔧 ADDED: Re-calculate analyzer tempo when the song (BPM) changes dynamically
        .onChange(of: playerManager.currentBPM) { oldBPM, newBPM in
            if playerManager.isPlaying {
                audioAnalyzer.stopMonitoring()
                audioAnalyzer.startMonitoring(bpm: newBPM)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                playerManager.stop()
                audioAnalyzer.stopMonitoring()
            }
        }
    }
}
