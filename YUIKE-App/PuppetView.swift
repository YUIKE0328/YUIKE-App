//
//  PuppetView.swift
//  YUIKE-App
//
//  Created by Kuniaki Yui on 2026/06/25.
//

import SwiftUI

struct PuppetView: View {
    let isPlaying: Bool
    let bassLevel: CGFloat // Accept real-time bass data (0.0 to 1.0)
    
    var body: some View {
        VStack(spacing: 4) {
            // 1. Head (Lyrics target)
            Circle()
                .fill(Color.purple)
                .frame(width: 60, height: 60)
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
                // Left Leg (Bends slightly more outwards with bass)
                Capsule()
                    .fill(Color.green)
                    .frame(width: 14, height: 50)
                    .rotationEffect(.degrees(isPlaying ? -15 - (bassLevel * 20) : 0), anchor: .top)
                
                // Right Leg (Bends slightly more outwards with bass)
                Capsule()
                    .fill(Color.green)
                    .frame(width: 14, height: 50)
                    .rotationEffect(.degrees(isPlaying ? 15 + (bassLevel * 20) : 0), anchor: .top)
            }
        }
        // --- SQUAT / BOUNCE EFFECT BASED ON BASS ---
        // Shifts down slightly when a heavy bass hits
        .offset(y: bassLevel * 40)
        // Squashes vertically to simulate a "kneebend / squat" motion
        .scaleEffect(x: 1.0 + (bassLevel * 0.1), y: 1.0 - (bassLevel * 0.25), anchor: .bottom)
        // Smooth out the motion using a spring animation linked to the level changes
        .animation(.spring(response: 0.10, dampingFraction: 0.45, blendDuration: 0), value: bassLevel)
    }
}

#Preview {
    PuppetView(isPlaying: true, bassLevel: 0.3)
}
