# TelloVideoH264Decoder
This contains a demo macOS app to illustrate how to use the TelloVideoH264Decoder

The TelloVideoH264Decoder serves like a demo decoder that can meet common requirement

I'm no expert on video decoding and I merely assemble code from different places and make it work. It could be a little buggy, and not world-class flexible for some configurations (e.g. `decodeFlags`) 

Therefore I will be grateful that if you can send me pull requests to make it better. 

## Get a valid NAL Unit
You need to first generate valid NALU either by yourself or by `getNalUnits()`/ `readNalUnits()`.

`getNalUnits(streamBuffer: Array<UInt8>) -> NALUnit?` will get all valid NALU and abandon incomplete NALU (data before next start code)

`readNalUnits(streamBuffer:inout Array<UInt8>) -> NALUnit?` will consume `streamBuffer`. To stop reading, call `stopProcessing()`

## Get CMSampleBuffer from NALU
Get a CMSampleBuffer by `getCMSampleBuffer(from nalu: NALUnit)`

## Get CVImageBuffer from CMSampleBuffer
Get a `CVImageBuffer` by calling `decompress()`

>decompress(sampleBuffer: CMSampleBuffer, outputHandler: @escaping VTDecompressionOutputHandler) -> OSStatus

This is a wrapper of `VTDecompressionSessionDecodeFrame(_:sampleBuffer:flags:infoFlagsOut:outputHandler:)`

note that
>outputHandler cannot be called with a session created with a VTDecompressionOutputCallbackRecord.

### what if I want to use VTDecompressionOutputCallbackRecord?
Grab the source code and modify `createVTDecompressionSession()` by commenting back 
```swift
var outputCallback = VTDecompressionOutputCallbackRecord()
outputCallback.decompressionOutputCallback = decodeFrameCallback
outputCallback.decompressionOutputRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
```
and pass to `outputCallback: ` in `VTDecompressionSessionCreate()`

## About CMSampleTimingInfo
I don't quite understand what each parameter means while creating the CMSampleTimingInfo. Even if I don't set it, the video streaming seems working well. Welcome any improvement and knowledge sharing.

## About renderVideoStream()
>renderVideoStream(streamBuffer: inout Array<UInt8>, to videoLayer: AVSampleBufferDisplayLayer)

This is a lazy method for people just want to display the video stream from Tello with  `AVSampleBufferDisplayLayer`

It simply keeps consuming `streamBuffer`, so you would want to put it into a `DispatchQueue` as it will block current thread, and be careful not causing write/read corruption. This also applies to `readNalUnits()`. 

## TelloVideoDecoderMac
This mac app contains similar code used in `TelloVideoH264Decoder`, just to demonstrate how to use it in different ways.

`startHandling()` behaves like `renderVideoStream()`. You only need one of them in `viewDidAppear()`.

Remember "get a valid NALU" is the first step, so `getNALUnit()` is similar to `getNalUnits()`/ `readNalUnits()`.

## One more thing
For more information, refer WWDC 2014 Session 513 "Direct Access to Video Encoding and Decoding"
