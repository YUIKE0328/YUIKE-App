//
//  AudioAnalyzer.swift
//  YUIKE-App
//
//  Created by Kuniaki Yui on 2026/06/25.
//

import Foundation
import Combine
import AVFoundation
import Accelerate

class AudioAnalyzer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var isRunning = false
    
    // Published variable to bound with PuppetView (0.0 to 1.0)
    @Published var bassLevel: CGFloat = 0.0
    
    func startMonitoring() {
        guard !isRunning else { return }
                
                // --- 🔧 ADD THIS BLOCK TO FIX THE CLASH ---
                // Tell iOS to mix playback and recording together smoothly
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
                    try session.setActive(true)
                } catch {
                    print("Failed to set up audio session category: \(error.localizedDescription)")
                }
                // ------------------------------------------
                
       
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Setup buffer and FFT (Fast Fourier Transform) analysis
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData?[0]
            let frameLength = UInt32(buffer.frameLength)
            
            if let data = channelData {
                self.analyzeFrequency(data: data, frameLength: frameLength, sampleRate: recordingFormat.sampleRate)
            }
        }
        
        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            print("Audio Engine start failed: \(error.localizedDescription)")
        }
    }
    
    func stopMonitoring() {
        if isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            isRunning = false
            DispatchQueue.main.async {
                self.bassLevel = 0.0
            }
        }
    }
    
    private func analyzeFrequency(data: UnsafeMutablePointer<Float>, frameLength: UInt32, sampleRate: Double) {
        let log2n = UInt(round(log2(Double(frameLength))))
        let bufferSizePOT = Int(1 << log2n)
        
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
        
        var realp = [Float](repeating: 0.0, count: bufferSizePOT / 2)
        var imagp = [Float](repeating: 0.0, count: bufferSizePOT / 2)
        
        // --- 🔧 FIX: Safely access array pointers using withUnsafeMutableBufferPointer ---
        realp.withUnsafeMutableBufferPointer { realBuffer in
            imagp.withUnsafeMutableBufferPointer { imagBuffer in
                
                var splitComplex = DSPSplitComplex(
                    realp: realBuffer.baseAddress!,
                    imagp: imagBuffer.baseAddress!
                )
                
                data.withMemoryRebound(to: DSPComplex.self, capacity: bufferSizePOT / 2) { typeConvertedComplexVectors in
                    vDSP_ctoz(typeConvertedComplexVectors, 2, &splitComplex, 1, vDSP_Length(bufferSizePOT / 2))
                }
                
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                
                var magnitudes = [Float](repeating: 0.0, count: bufferSizePOT / 2)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(bufferSizePOT / 2))
                
                vDSP_destroy_fftsetup(fftSetup)
                
                // Calculate Bass frequency range (approx. 60Hz - 250Hz)
                let binSize = sampleRate / Double(bufferSizePOT)
                let minBin = Int(60.0 / binSize)
                let maxBin = Int(250.0 / binSize)
                
                var bassSum: Float = 0.0
                var count = 0
                
                for bin in minBin...maxBin {
                    if bin < magnitudes.count {
                        bassSum += sqrt(magnitudes[bin])
                        count += 1
                    }
                }
                
                let averageBass = count > 0 ? (bassSum / Float(count)) : 0.0
                
                // Normalize the level into 0.0 - 1.0 range with sensitivity tuning
                let sensitivity: Float = 30.0
                let normalized = min(max(averageBass / sensitivity, 0.0), 1.0)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    // Smooth response using low-pass filter logic
                    // self.bassLevel = CGFloat(normalized * 0.4 + Float(self.bassLevel) * 0.6)
                    
                    let dynamicBass = normalized * 1.5
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.bassLevel = CGFloat(dynamicBass * 0.7 + Float(self.bassLevel) * 0.3)
                    }
                }
            }
        }
    }
}
