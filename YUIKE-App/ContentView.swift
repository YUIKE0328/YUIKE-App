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
    // Add the audio analyzer to the view
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
                
                // Pass the real-time bass level to the puppet
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
        // Start/Stop audio monitoring based on playback state
        .onChange(of: playerManager.isPlaying) { oldState, isPlaying in
            if isPlaying {
                audioAnalyzer.startMonitoring()
            } else {
                audioAnalyzer.stopMonitoring()
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
