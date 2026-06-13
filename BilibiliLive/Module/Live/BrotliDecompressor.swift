//
//  BrotliDecompressor.swift
//  BilibiliLive
//
//  Created by yicheng on 2025/3/16.
//
import Compression
import Foundation

class BrotliDecompressor {
    private let bufferPool = DecompressionBufferPool()

    func decompressed(compressed: Data) -> Data? {
        guard !compressed.isEmpty else { return nil }
        let decodedCapacity = bufferPool.bufferSize
        let decodedDestinationBuffer = bufferPool.getBuffer()
        defer {
            bufferPool.returnBuffer(decodedDestinationBuffer)
        }

        let decompressed: Data? = compressed.withUnsafeBytes { encodedSourceBuffer in
            guard let base = encodedSourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return nil }
            let decodedCharCount = compression_decode_buffer(
                decodedDestinationBuffer,
                decodedCapacity,
                base, compressed.count,
                nil,
                COMPRESSION_BROTLI
            )
            if decodedCharCount == 0 {
                return nil
            }
            if decodedCharCount == decodedCapacity {
                // Output filled the buffer exactly -> likely truncated. Retry once with a larger buffer
                // (popular rooms can exceed 1MB after Brotli expansion).
                let bigCapacity = decodedCapacity * 8
                let bigBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bigCapacity)
                defer { bigBuffer.deallocate() }
                let n = compression_decode_buffer(bigBuffer, bigCapacity, base, compressed.count, nil, COMPRESSION_BROTLI)
                return n > 0 ? Data(bytes: bigBuffer, count: n) : nil
            }

            return Data(bytes: decodedDestinationBuffer, count: decodedCharCount)
        }
        return decompressed
    }
}

private class DecompressionBufferPool {
    let bufferSize: Int

    private var availableBuffers: [UnsafeMutablePointer<UInt8>] = []
    private let lock = NSLock()
    private let maxBuffers: Int

    init(bufferSize: Int = 1_000_000, maxBuffers: Int = 5) {
        self.bufferSize = bufferSize
        self.maxBuffers = maxBuffers
    }

    func getBuffer() -> UnsafeMutablePointer<UInt8> {
        lock.lock()
        defer { lock.unlock() }

        if let buffer = availableBuffers.popLast() {
            return buffer
        }
        return UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    }

    func returnBuffer(_ buffer: UnsafeMutablePointer<UInt8>) {
        lock.lock()
        defer { lock.unlock() }

        if availableBuffers.count < maxBuffers {
            availableBuffers.append(buffer)
        } else {
            buffer.deallocate()
        }
    }

    deinit {
        for buffer in availableBuffers {
            buffer.deallocate()
        }
    }
}
