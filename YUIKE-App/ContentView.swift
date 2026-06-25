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
    }
}

struct MediaPickerRepresentation: UIViewControllerRepresentable {
    let playerManager: MusicPlayerManager
    
    func makeUIViewController(context: Context) -> MPMediaPickerController {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MPMediaPickerControllerDelegate {
        var parent: MediaPickerRepresentation
        
        init(_ parent: MediaPickerRepresentation) {
            self.parent = parent
        }
        
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            parent.playerManager.setCollection(mediaItemCollection)
            mediaPicker.dismiss(animated: true, completion: nil)
        }
        
        func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
            mediaPicker.dismiss(animated: true, completion: nil)
        }
    }
}
