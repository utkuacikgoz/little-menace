import AVFoundation
import SwiftUI

/// Turns a SwiftUI card into a short looping MP4 for TikTok, Reels and Stories: each frame is the
/// card drawn at a moment in time. Made on the phone; nothing is uploaded.
enum CardVideo {
    @MainActor
    static func make<V: View>(size: CGSize, seconds: Double = 4, fps: Int32 = 24, scale: CGFloat = 3,
                              frame: (Double) -> V) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("little-menace-\(UUID().uuidString.prefix(8)).mp4")
        let width = Int(size.width * scale), height = Int(size.height * scale)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
        ])
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        writer.startSession(atSourceTime: .zero)
        for i in 0..<Int(seconds * Double(fps)) {
            let renderer = ImageRenderer(content: frame(Double(i) / Double(fps)))
            renderer.scale = scale
            guard let image = renderer.cgImage, let pool = adaptor.pixelBufferPool else { continue }
            var buffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            guard let buffer else { continue }
            CVPixelBufferLockBaseAddress(buffer, [])
            let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            CVPixelBufferUnlockBaseAddress(buffer, [])
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
            adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: fps))
        }
        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        return url
    }
}
