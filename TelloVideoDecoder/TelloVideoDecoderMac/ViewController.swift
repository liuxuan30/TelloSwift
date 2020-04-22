//
//  ViewController.swift
//  TelloVideoDecoderMac
//
//  Created by Xuan Liu on 2019/12/20.
//  Copyright © 2020 Xuan Liu. All rights reserved.
//

import Cocoa
import AVFoundation
import VideoToolbox
import TelloSwift


class ViewController: NSViewController, TelloVideoSteam {

    var videoLayer: AVSampleBufferDisplayLayer?

    var streamBuffer = Array<UInt8>()

    let decoder = TelloVideoH264Decoder()

    var tello: Tello!

    let startCode: [UInt8] = [0,0,0,1]


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        tello = Tello()
        tello.videoDelegate = self
        print("connected:", tello.activate())
        print("battery:", tello.battery)
        tello.enable(video: true)
        tello.keepAlive(every: 10)

        videoLayer = AVSampleBufferDisplayLayer()
        if let layer = videoLayer {
            layer.frame = CGRect(x: 0, y: 0, width: 1280, height: 720)
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill

            let _CMTimebasePointer = UnsafeMutablePointer<CMTimebase?>.allocate(capacity: 1)
            let status = CMTimebaseCreateWithMasterClock( allocator: kCFAllocatorDefault, masterClock: CMClockGetHostTimeClock(),  timebaseOut: _CMTimebasePointer )
            layer.controlTimebase = _CMTimebasePointer.pointee

            if let controlTimeBase = layer.controlTimebase, status == noErr {
                CMTimebaseSetTime(controlTimeBase, time: CMTime.zero);
                CMTimebaseSetRate(controlTimeBase, rate: 1.0);
            }

            self.view.layer = layer
            self.view.wantsLayer = true
            layer.display()
        }
    }

    override func viewDidAppear() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(2))) { [unowned self] in
            // use either startHandle() or decoder.renderVideoStream(),
            // they just behave in different ways, but eventually the same, giving more flexibility
//            self.startHandle()
            self.decoder.renderVideoStream(streamBuffer: &self.streamBuffer, to: self.videoLayer!)
        }
    }

    override func viewWillDisappear() {
        tello.clearTimer()
        tello.shutdown()
    }

    func telloStream(receive frame: Data?) {

        if let frame = frame {
            let packet = [UInt8](frame)
            streamBuffer.append(contentsOf: packet)
        }
    }

    public typealias NALU = Array<UInt8>
    func getNALUnit() -> NALU? {

        if streamBuffer.count == 0 {
            return nil
        }

        //make sure start with start code
        if streamBuffer.count < 5 || Array(streamBuffer[0...3]) != startCode {
            return nil
        }

        //find second start code, so startIndex = 4
        var startIndex = 4

        while true {

            while ((startIndex + 3) < streamBuffer.count) {
                if Array(streamBuffer[startIndex...startIndex+3]) == startCode {

                    let packet = Array(streamBuffer[0..<startIndex])
                    streamBuffer.removeSubrange(0..<startIndex)

                    return packet
                }
                startIndex += 1
            }

            // not found next start code , read more data
            if streamBuffer.count == 0 {
                return nil
            }
        }
    }

    func startHandling() {
        while let packet = getNALUnit() {
            if let sampleBuffer = decoder.getCMSampleBuffer(from: packet) {
                let attachments:CFArray? = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true)
                if let attachmentArray = attachments {
                    let dic = unsafeBitCast(CFArrayGetValueAtIndex(attachmentArray, 0), to: CFMutableDictionary.self)

                    CFDictionarySetValue(dic,
                                         Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                                         Unmanaged.passUnretained(kCFBooleanTrue).toOpaque())
                }

                videoLayer?.enqueue(sampleBuffer)
                DispatchQueue.main.async(execute: {
                    self.videoLayer?.needsDisplay()
                })
            }
        }
    }
}
