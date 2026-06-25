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
    @State private var showPicker = false
    
    // Environment value to track the app's current lifecycle state
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 30) {
            Text("Audio Visualizer")
                .font(.title)
                .bold()
            
            // Visualizer Placeholder Animation
            Circle()
                .fill(playerManager.isPlaying ? Color.purple : Color.gray)
                .frame(width: 150, height: 150)
                .scaleEffect(playerManager.isPlaying ? 1.1 : 1.0)
                .animation(playerManager.isPlaying ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default, value: playerManager.isPlaying)
            
            VStack(spacing: 10) {
                Text(playerManager.currentTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(playerManager.playbackState)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 40) {
                Button(action: {
                    showPicker = true
                }) {
                    Text("Select Song")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    playerManager.playOrPause()
                }) {
                    Text(playerManager.isPlaying ? "Pause" : "Play")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showPicker) {
            MediaPickerRepresentation(playerManager: playerManager)
        }
        // Detect when the app is closed or moved to the background
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                playerManager.stop()
            }
        }
    }
}
