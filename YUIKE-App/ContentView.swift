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
    
    // UserDefaults key for saving manual BPM preference
    private let savedManualBPMKey = "UserSavedManualBPM"
    
    // 🔧 CHANGE: Initialize directly from UserDefaults, fallback to 120 if empty
    @State private var manualBPM: Double
    
    init() {
        let storedBPM = UserDefaults.standard.double(forKey: "UserSavedManualBPM")
        // If no value exists, double(forKey:) returns 0.0, so we default to 120.0
        _manualBPM = State(initialValue: storedBPM > 0 ? storedBPM : 120.0)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("YUIKE App")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                PuppetView(isPlaying: playerManager.isPlaying, bassLevel: audioAnalyzer.bassLevel)
                
                Spacer()
                
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
        .onChange(of: playerManager.isPlaying) { oldState, isPlaying in
            if isPlaying {
                audioAnalyzer.startMonitoring(bpm: manualBPM)
            } else {
                audioAnalyzer.stopMonitoring()
            }
        }
        // 🔧 CHANGE: Update the puppet speed AND save the preference locally immediately
        .onChange(of: manualBPM) { oldBPM, newBPM in
            UserDefaults.standard.set(newBPM, forKey: "UserSavedManualBPM")
            if playerManager.isPlaying {
                audioAnalyzer.stopMonitoring()
                audioAnalyzer.startMonitoring(bpm: newBPM)
            }
        }
        // 🔧 DELETED: .onChange(of: playerManager.currentBPM) has been removed!
        // This ensures shifting songs will NO LONGER override user's manual preference.
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
        // 🔧 ADDED: Refresh the visualizer loop immediately when the track automatically advances
        .onChange(of: playerManager.currentTitle) { oldTitle, newTitle in
            if playerManager.isPlaying {
                audioAnalyzer.stopMonitoring()
                audioAnalyzer.startMonitoring(bpm: manualBPM)
            }
        }
    }
}
