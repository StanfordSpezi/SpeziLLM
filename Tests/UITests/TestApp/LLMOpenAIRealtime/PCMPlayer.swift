//
// This source file is part of the Stanford Spezi open source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

@preconcurrency import AVFAudio
import Foundation
import OSLog


class PCMPlayer {
    private static let logger = Logger(subsystem: "edu.stanford.spezi", category: "SpeziLLMUITests")

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let inputFormat: AVAudioFormat // raw PCM16 data format from OpenAI

    init(sampleRate: Double = 24000, channels: AVAudioChannelCount = 1) {
        // 24000 Hz is the default sampleRate from OpenAI's APIs
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        ) else {
            fatalError("Failed to create PCM format")
        }
        self.inputFormat = format

        audioEngine.attach(playerNode)

        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: outputFormat)

        do {
            try audioEngine.start()
        } catch {
            Self.logger.error("Error starting audio engine: \(error)")
        }
    }

    // swiftlint:disable:next function_body_length
    func play(rawPCMData data: Data) {
        let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
        var finalBuffer: AVAudioPCMBuffer?

        let bytesPerFrame = inputFormat.streamDescription.pointee.mBytesPerFrame
        let inputFrameCount = UInt32(data.count) / bytesPerFrame

        // Check if conversion is necessary.
        if inputFormat.sampleRate != outputFormat.sampleRate {
            // Conversion is needed.
            guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
                Self.logger.error("Failed to initialize audio converter")
                return
            }

            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount) else {
                Self.logger.error("Failed to create input PCM buffer")
                return
            }
            inputBuffer.frameLength = inputFrameCount
            // Fill the input buffer with raw PCM data.
            data.withUnsafeBytes { rawBuffer in
                if let baseAddress = rawBuffer.baseAddress {
                    memcpy(inputBuffer.int16ChannelData?[0], baseAddress, data.count)
                }
            }

            // Calculate the number of output frames expected.
            let ratio = outputFormat.sampleRate / inputFormat.sampleRate
            let outputFrameCapacity = UInt32(Double(inputFrameCount) * ratio)

            guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else {
                Self.logger.error("Failed to create output PCM buffer")
                return
            }

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }

            let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
            if status != .haveData && status != .inputRanDry {
                Self.logger.error("Conversion error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            finalBuffer = outputBuffer
        } else {
            // No conversion needed between input and output audio format
            guard let buffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount) else {
                Self.logger.error("Failed to create PCM buffer")
                return
            }
            buffer.frameLength = inputFrameCount
            data.withUnsafeBytes { rawBuffer in
                if let baseAddress = rawBuffer.baseAddress {
                    memcpy(buffer.int16ChannelData?[0], baseAddress, data.count)
                }
            }
            finalBuffer = buffer
        }

        guard let bufferToPlay = finalBuffer else {
            Self.logger.error("No valid buffer to play")
            return
        }

        // Schedule the (converted) buffer and play.
        playerNode.scheduleBuffer(bufferToPlay)
        playerNode.play()
    }
}
