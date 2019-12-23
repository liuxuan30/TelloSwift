//
//  TelloVideoHandler.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/26.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//  Licensed under Apache License 2.0
//

import Foundation
import NIO

public protocol TelloVideoSteam: AnyObject {
    /// Obtain video frame, this is dispatched to global user interactive queue.
    /// - Parameter frame: Any
    func telloStream(receive frame: Data?)
}

class TelloVideoHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    weak var delegate: TelloVideoSteam?
    var streamBuffer = [UInt8]()
    var lastBytes = [UInt8]()

    init(delegate: TelloVideoSteam? = nil) {
        self.delegate = delegate
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("[TELLO-VIDEO-] error:", error)
        context.fireErrorCaught(error)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data).data
        if let segment = buffer.readBytes(length: buffer.readableBytes) {
            streamBuffer.append(contentsOf: segment)
            lastBytes = segment
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        if lastBytes.count < 1460 {
            let frame = streamBuffer
            streamBuffer.removeAll(keepingCapacity: true)
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                self?.delegate?.telloStream(receive: Data(frame))
            }
        }
    }
}
