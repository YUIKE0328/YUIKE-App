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
    
    // 🔧 ADDED: State to hold user-controlled manual BPM
    @State private var manualBPM: Double = 120.0

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("YUIKE App")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                // Pass animation level to the puppet
                PuppetView(isPlaying: playerManager.isPlaying, bassLevel: audioAnalyzer.bassLevel)
                
                Spacer()

                VStack(spacing: 8) {
                    Text(playerManager.currentTitle)
                        .font(.subheadline)
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text(playerManager.playbackState)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
                
                // 🔧 ADDED: BPM manual slider control section
                VStack(spacing: 10) {
                    Text("Adjust Puppet Tempo: \(Int(manualBPM)) BPM")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Slider(value: $manualBPM, in: 60...200, step: 1)
                        .padding(.horizontal, 40)
                        .accentColor(.blue)
                }
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
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
        // 🔧 CHANGE: Start monitoring with user's manual BPM state
        .onChange(of: playerManager.isPlaying) { oldState, isPlaying in
            if isPlaying {
                audioAnalyzer.startMonitoring(bpm: manualBPM)
            } else {
                audioAnalyzer.stopMonitoring()
            }
        }
        // 🔧 ADDED: Update the puppet speed in real-time when user drags the slider
        .onChange(of: manualBPM) { oldBPM, newBPM in
            if playerManager.isPlaying {
                audioAnalyzer.stopMonitoring()
                audioAnalyzer.startMonitoring(bpm: newBPM)
            }
        }
        // 🔧 ADDED: When a new song loads, overwrite slider with the song's estimated BPM
        .onChange(of: playerManager.currentBPM) { oldBPM, newBPM in
            self.manualBPM = newBPM
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                playerManager.saveCurrentPlaybackTime()
                audioAnalyzer.stopMonitoring()
            } else if newPhase == .active {
                if playerManager.isPlaying {
                    audioAnalyzer.startMonitoring(bpm: manualBPM)
                }
            }
        }
    }
}
