//
//  AudioAnalyzer.swift
//  YUIKE-App
//
//  Created by Kuniaki Yui on 2026/06/25.
//

import Foundation
import Combine

class AudioAnalyzer: ObservableObject {
    @Published var bassLevel: CGFloat = 0.0
    
    private var timer: AnyCancellable?
    private var timeCounter: Double = 0.0
    
    // 🔧 CHANGE: Accept target BPM to calculate exact physics matching the rhythm
    func startMonitoring(bpm: Double) {
        guard timer == nil else { return }
        
        let fps = 60.0
        // Convert BPM (Beats Per Minute) into radians increment per frame for a smooth 1-beat loop
        // Formula: (BPM / 60 seconds) * 2 * PI / FPS
        let stepIncrement = (bpm / 60.0) * Double.pi / fps
        
        timer = Timer.publish(every: 1.0 / fps, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Progress time based on current song tempo
                self.timeCounter += stepIncrement
                
                // Perfect rhythmic bounce aligned with the beat
                let rawWave = abs(sin(self.timeCounter))
                
                // Add natural flavor
                let noise = Double.random(in: -0.03...0.03)
                let normalized = min(max(rawWave + noise, 0.0), 1.0)
                
                // Smooth frame filter
                self.bassLevel = CGFloat(normalized * 0.85 + Double(self.bassLevel) * 0.15)
            }
    }
    
    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        timeCounter = 0.0
        bassLevel = 0.0
    }
}
