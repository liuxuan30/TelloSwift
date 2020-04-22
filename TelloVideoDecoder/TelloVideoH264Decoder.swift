//
//  TelloVideoH264Decoder.swift
//
//  Created by Xuan Liu on 2019/12/25.
//  Copyright © 2020 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation
import VideoToolbox
import AVFoundation

public typealias NALUnit = Array<UInt8>

public class TelloVideoH264Decoder {

    let startCode: NALUnit = [0, 0, 0, 1]

    var formatDesc: CMVideoFormatDescription?
    var vtdSession: VTDecompressionSession?

    var sps: NALUnit?
    var pps: NALUnit?

    var stop = true


    /// Decode a stream buffer which contains H264 raw bytes, enqueue the CMSampleBuffer to AVSampleBufferDisplayLayer you provided, and call setNeedsDisplay for you.
    ///
    /// You normally would want to call this function in a DispatchQueue, as it will block current thread, since it keeps consuming the stream buffer.
    ///
    /// - Parameters:
    ///   - streamBuffer: inout Array<UInt8>
    ///   - videoLayer: AVSampleBufferDisplayLayer
    public func renderVideoStream(streamBuffer: inout Array<UInt8>, to videoLayer: AVSampleBufferDisplayLayer) {
        stop = false
        while let nalu = readNalUnits(streamBuffer: &streamBuffer) {
            guard !stop else { break }

            if let sampleBuffer = getCMSampleBuffer(from: nalu) {
                let attachments:CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
                if let attachmentArray = attachments {
                    let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentArray, 0), to: CFMutableDictionary.self)

                    CFDictionarySetValue(dic,
                                         Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                         Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
                }

                videoLayer.enqueue(sampleBuffer)
                DispatchQueue.main.async { videoLayer.needsDisplay() }
            }
        }
    }

    /// Stop consuming stream buffer and clean up decoding resources
    ///
    /// This function will call cleanUp() to free resources
    public func stopProcessing() {
        stop = true
        cleanUp()
    }

    /// This is a wrapper of VTDecompressionSessionDecodeFrame(_:sampleBuffer:flags:infoFlagsOut:outputHandler:)
    /// - Parameters:
    ///   - sampleBuffer: CMSampleBuffer
    ///   - outputHandler: @escaping VTDecompressionOutputHandler
    /// - Returns: OSStatus
    public func decompress(sampleBuffer: CMSampleBuffer, outputHandler: @escaping VTDecompressionOutputHandler) -> OSStatus {
        guard let session = vtdSession else { return -1 }
        return VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuffer, flags: [._EnableAsynchronousDecompression, ._EnableTemporalProcessing], infoFlagsOut: nil, outputHandler: outputHandler)
    }

    /// Create a CMSampleBuffer from a NAL unit. You must pass a valid NAL Unit in order to get the correct CMSampleBuffer.
    /// - Parameter nalu: NALUnit, Array<UInt8>
    /// - Returns: CMSampleBuffer?
    public func getCMSampleBuffer(from nalu: NALUnit) -> CMSampleBuffer? {
//        print("Read Nalu size \(nalu.count)");
        var mNalu = nalu
        let naluType = nalu[4] & 0x1f

        var sampleBuffer: CMSampleBuffer?
        switch naluType {
        case 0x05:  // I frame
//            print("Nal type is IDR frame")
            guard initialize(SPS: sps, PPS: pps) else { break }
            sampleBuffer = decodeToCMSampleBuffer(frame: &mNalu)

        case 0x07:  // SPS
//            print("Nal type is SPS")
            sps = NALUnit(nalu[4...])

        case 0x08:  // PPS
//            print("Nal type is PPS")
            pps = NALUnit(nalu[4...])

        default:  // B/P Frame
//            print("Nal type is B/P frame")
            sampleBuffer = decodeToCMSampleBuffer(frame:&mNalu)
        }

        return sampleBuffer
    }


    /// Get as many as possible NALU units from stream, incomplete unit will be dropped
    /// - Parameter streamBuffer: StreamData, Array<UInt8>
    /// - Returns: NALUnit?
    public func getNalUnits(streamBuffer: Array<UInt8>) -> NALUnit? {
        guard streamBuffer.count != 0 else { return nil }

        //make sure start with start code
        if streamBuffer.count < 5 || Array(streamBuffer[0...3]) != startCode {
            return nil
        }

        var nalUnits = Array<UInt8>()
        //find second start code, so startIndex = 4
        var startIndex = 4

        while ((startIndex + 3) < streamBuffer.count) {
            if Array(streamBuffer[startIndex...startIndex+3]) == startCode {
                let units = Array(streamBuffer[0..<startIndex])
                nalUnits.append(contentsOf: units)
            }
            startIndex += 1
        }

        return nalUnits
    }

    /// Read NAL Units from an inout streamBuffer
    /// - Parameter streamBuffer: inout Array<UInt8>
    /// - Returns: NALUnit?
    public func readNalUnits(streamBuffer:inout Array<UInt8>) -> NALUnit? {
        guard streamBuffer.count != 0 else { return nil }

        //make sure start with start code
        if streamBuffer.count < 5 || Array(streamBuffer[0...3]) != startCode {
            return nil
        }

        //find second start code, so startIndex = 4
        var startIndex = 4

        while true {
            guard !stop else { return nil }
            while ((startIndex + 3) < streamBuffer.count) {
                if Array(streamBuffer[startIndex...startIndex+3]) == startCode {

                    let units = Array(streamBuffer[0..<startIndex])
                    streamBuffer.removeSubrange(0..<startIndex)

                    return units
                }
                startIndex += 1
            }

            // not found next start code, read more data
            if streamBuffer.count == 0 {
                return nil
            }
        }
    }

    /// Free all decoder resources
    ///
    /// If you called stopProcessing(), you don't have to call this.
    public func cleanUp() {
        if let session = vtdSession {
            VTDecompressionSessionInvalidate(session)
            vtdSession = nil
        }

        formatDesc = nil
        sps = nil
        pps = nil
    }

    func decodeToCMSampleBuffer(frame: inout NALUnit) -> CMSampleBuffer? {
        guard vtdSession != nil else { return nil }
        var bigLen = CFSwapInt32HostToBig(UInt32(frame.count - 4))
        memcpy(&frame, &bigLen, 4)
        var blockBuffer: CMBlockBuffer?
        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault, memoryBlock: &frame, blockLength: frame.count, blockAllocator: kCFAllocatorNull, customBlockSource: nil, offsetToData: 0, dataLength: frame.count, flags: 0, blockBufferOut: &blockBuffer)

        guard status == kCMBlockBufferNoErr else { return nil }

        var sampleBuffer: CMSampleBuffer?
        let sampleSizeArray = [frame.count]

//        let timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 25), presentationTimeStamp: CMTime(seconds: 1, preferredTimescale: 25), decodeTimeStamp: CMTime.invalid)

        status = CMSampleBufferCreateReady(allocator: kCFAllocatorDefault, dataBuffer: blockBuffer, formatDescription: formatDesc, sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: sampleSizeArray.count, sampleSizeArray: sampleSizeArray, sampleBufferOut: &sampleBuffer)

        guard status == noErr else { return nil }
        return sampleBuffer
    }

    func initialize(SPS: NALUnit?, PPS: NALUnit?) -> Bool {
        guard let SPS = SPS, let PPS = PPS else { return false }
        guard createH264FormatDescription(SPS: SPS, PPS: PPS) == noErr else { return false }
        guard createVTDecompressionSession() == noErr else { return false }
        return true
    }

    func createH264FormatDescription(SPS sps: Array<UInt8>, PPS pps: Array<UInt8>) -> OSStatus {
        if formatDesc != nil { formatDesc = nil }

        let status = sps.withUnsafeBufferPointer { spsBP -> OSStatus in //<- Specify return type explicitly.
            pps.withUnsafeBufferPointer { ppsBP in
                let paramSet = [spsBP.baseAddress!, ppsBP.baseAddress!]
                let paramSizes = [spsBP.count, ppsBP.count]
                return paramSet.withUnsafeBufferPointer { paramSetBP in
                    paramSizes.withUnsafeBufferPointer { paramSizesBP in
                        CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault, parameterSetCount: 2, parameterSetPointers: paramSetBP.baseAddress!, parameterSetSizes: paramSizesBP.baseAddress!, nalUnitHeaderLength: 4, formatDescriptionOut: &formatDesc)
                    }
                }
            }
        }

        return status
    }

    func createVTDecompressionSession() -> OSStatus {
        guard formatDesc != nil else { return -1 }

        if let session = vtdSession {
            let accept = VTDecompressionSessionCanAcceptFormatDescription(session, formatDescription: formatDesc!)
            guard !accept else { return 0 }
            // if current session cannot aceept the format, invalidate and create a new one
            VTDecompressionSessionInvalidate(session)
            vtdSession = nil
        }

        var decoderParameters: [String: CFBoolean]?
        #if os(macOS)
        decoderParameters = [String: CFBoolean]()
        decoderParameters!.updateValue(kCFBooleanTrue, forKey: kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder as String)
        #endif

        var destPBAttributes = [String: UInt32]()
        destPBAttributes.updateValue(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, forKey: kCVPixelBufferPixelFormatTypeKey as String)

        // comment below back and pass to VTDecompressionSessionCreate if you don't want to call VTDecompressionSessionDecodeFrame(_:sampleBuffer:flags:infoFlagsOut:outputHandler:)
//        var outputCallback = VTDecompressionOutputCallbackRecord()
//        outputCallback.decompressionOutputCallback = decodeFrameCallback
//        outputCallback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // pass outputCallback above to outputCallback if you need
        let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault, formatDescription: formatDesc!, decoderSpecification: decoderParameters as CFDictionary?, imageBufferAttributes: destPBAttributes as CFDictionary, outputCallback: nil, decompressionSessionOut: &vtdSession)

        return status
    }
}

func decodeFrameCallback(_ decompressionOutputRefCon: UnsafeMutableRawPointer?, _ sourceFrameRefCon: UnsafeMutableRawPointer?, _ status: OSStatus, _ infoFlags: VTDecodeInfoFlags, _ imageBuffer: CVImageBuffer?, _ presentationTimeStamp: CMTime, _ presentationDuration: CMTime) -> Void {
    // only get called if you create VTDecompressionOutputCallbackRecord and pass to VTDecompressionSessionCreate(outputCallback:)

}

