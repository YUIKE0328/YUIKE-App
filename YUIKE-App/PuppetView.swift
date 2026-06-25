//
//  PuppetView.swift
//  YUIKE-App
//
//  Created by Kuniaki Yui on 2026/06/25.
//

import SwiftUI

struct PuppetView: View {
    let isPlaying: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // 1. Head (Lyrics target)
            Circle()
                .fill(Color.purple)
                .frame(width: 60, height: 60)
                // Fake lyrics trigger animation (Nodding)
                .rotationEffect(.degrees(isPlaying ? 8 : 0), anchor: .bottom)
                .animation(isPlaying ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default, value: isPlaying)
            
            // 2. Torso & Arms (Treble target)
            HStack(spacing: 8) {
                // Left Arm
                Capsule()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 10, height: 60)
                    .rotationEffect(.degrees(isPlaying ? -40 : -10), anchor: .top)
                
                // Body Main
                Capsule()
                    .fill(Color.blue)
                    .frame(width: 40, height: 90)
                
                // Right Arm
                Capsule()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 10, height: 60)
                    .rotationEffect(.degrees(isPlaying ? 40 : 10), anchor: .top)
            }
            .offset(x: isPlaying ? 3 : 0)
            .animation(isPlaying ? .linear(duration: 0.1).repeatForever(autoreverses: true) : .default, value: isPlaying)
            
            // 3. Legs / Lower Body (Bass target)
            HStack(spacing: 12) {
                // Left Leg
                Capsule()
                    .fill(Color.green)
                    .frame(width: 14, height: 50)
                    .rotationEffect(.degrees(isPlaying ? -15 : 0), anchor: .top)
                
                // Right Leg
                Capsule()
                    .fill(Color.green)
                    .frame(width: 14, height: 50)
                    .rotationEffect(.degrees(isPlaying ? 15 : 0), anchor: .top)
            }
            .offset(y: isPlaying ? -10 : 0)
            .animation(isPlaying ? .interpolatingSpring(stiffness: 300, damping: 10).repeatForever(autoreverses: true) : .default, value: isPlaying)
        }
    }
}

// Preview provider for Xcode design canvas
#Preview {
    PuppetView(isPlaying: true)
}
