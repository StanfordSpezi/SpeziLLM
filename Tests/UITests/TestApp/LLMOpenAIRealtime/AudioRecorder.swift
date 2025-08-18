import AVFoundation
import SwiftUI


//@MainActor
@Observable
class AudioRecorder {
    @ObservationIgnored private let audioEngine = AVAudioEngine()

    var isRecording = false

    private(set) var audioBufferContinuation: AsyncStream<Data>.Continuation?
    private(set) var audioBufferStream: AsyncStream<Data>?
    
    private var converter: AVAudioConverter?
    private let targetFormat: AVAudioFormat
    private var audioConfigChangeObserver: NSObjectProtocol?
    
    init(sampleRate: Double = 24000, channels: AVAudioChannelCount = 1) {
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        ) else {
            fatalError("Failed to create PCM format")
        }
        self.targetFormat = targetFormat

        setupAudioSession()
        setupAudioEngine()

        
//        self.audioConfigChangeObserver = NotificationCenter.default.addObserver(
//            forName: .AVAudioEngineConfigurationChange, object: audioEngine, queue: .main
//        ) { [weak self] _ in
////            Task { @MainActor in
//                print("Audio change!")
////
//                guard let inputFormat = self?.audioEngine.inputNode.outputFormat(forBus: 0),
//                      let targetFormat = self?.targetFormat else {
//                    return
//                }
//                
//                self?.converter = AVAudioConverter(from: inputFormat, to: targetFormat)
////            }
//        }
        
        audioEngine.prepare()
    }
    
    func start() {
        guard !audioEngine.isRunning else {
            print("Audio engine already running")
            return
        }

        isRecording = true

        do {
            try audioEngine.start()
        } catch {
            print("Couldn't start audio engine")
        }
    }

    func stop() {
        isRecording = false
        audioEngine.stop()
    }

    private func setupAudioSession(sampleRate: Double = 24000) {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        } catch {
            print("Could not set the audio category: \(error.localizedDescription)")
        }

        do {
            try session.setPreferredSampleRate(sampleRate)
        } catch {
            print("Could not set the preferred sample rate: \(error.localizedDescription)")
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Could not set the audio session to active: \(error.localizedDescription)")
        }
    }

    private func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        do {
            try inputNode.setVoiceProcessingEnabled(true)
        } catch {
            print("Could not enable voice processing \(error)")
            return
        }

        inputNode.reset()
        inputNode.removeTap(onBus: 0)
        
        let inputFormat = inputNode.outputFormat(forBus: 0)
        converter = AVAudioConverter(from: inputFormat, to: targetFormat)

        audioBufferStream = AsyncStream<Data> { continuation in
            self.audioBufferContinuation = continuation

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
                guard let converter = self.converter else {
                    return
                }

                // Prepare an output buffer big enough for the converted frames.
                let inFrames = AVAudioFrameCount(buffer.frameLength)
                let ratio = self.targetFormat.sampleRate / inputFormat.sampleRate
                let outCapacity = AVAudioFrameCount(Double(inFrames) * ratio + 8) // +epsilon

                guard let outBuffer = AVAudioPCMBuffer(pcmFormat: self.targetFormat, frameCapacity: outCapacity) else {
                    return
                }

                var hasSetStatus = false
                var error: NSError?

                let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                    // Provide the input buffer once
                    if hasSetStatus {
                        outStatus.pointee = .noDataNow
                        return nil
                    } else {
                        hasSetStatus = true
                        outStatus.pointee = .haveData
                        return buffer
                    }
                }

                let status = converter.convert(to: outBuffer, error: &error, withInputFrom: inputBlock)
                if status == .error || error != nil {
                    print("Conversion error: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                // Convert to Data
                if let data = self.monoPcmToInt16Data(from: outBuffer) {
                    continuation.yield(data)
                }
            }
        }
    }
    
    private func monoPcmToInt16Data(from buffer: AVAudioPCMBuffer) -> Data? {
        // Expecting interleaved Int16
        guard buffer.format.commonFormat == .pcmFormatInt16,
              buffer.format.channelCount == 1,
              let ch0 = buffer.int16ChannelData?.pointee else {
            return nil
        }

        let bytesPerFrame = Int(buffer.format.streamDescription.pointee.mBytesPerFrame)
        let size = Int(buffer.frameLength) * bytesPerFrame
        
        return Data(bytes: ch0, count: size)
    }
}
