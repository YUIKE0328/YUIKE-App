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
    
    func startMonitoring() {
        guard timer == nil else { return }
        
        // 60 FPS smoother timer loop
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Advance time counter
                self.timeCounter += 0.25
                
                // Generate a pseudo-BPM rhythmic bounce using absolute sine wave
                let rawWave = abs(sin(self.timeCounter))
                
                // Add a bit of natural variation so it doesn't look completely robotic
                let noise = Double.random(in: -0.05...0.05)
                let normalized = min(max(rawWave + noise, 0.0), 1.0)
                
                // Apply a gentle low-pass filter for smooth bone movement
                self.bassLevel = CGFloat(normalized * 0.8 + Double(self.bassLevel) * 0.2)
            }
    }
    
    func stopMonitoring() {
        timer?.cancel()
        timer = nil
        timeCounter = 0.0
        bassLevel = 0.0
    }
}
