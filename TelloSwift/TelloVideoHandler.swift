//
//  TelloVideoHandler.swift
//  TelloSwift
//
//  Created by Xuan on 2019/11/26.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import Foundation
import NIO

public protocol TelloVideoSteam: AnyObject {
    /// Obtain video frame, this is dispatched to global user interactive queue.
    /// - Parameter frame: Any
    func telloStream(receive frame: Any)
}

class TelloVideoHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    weak var delegate: TelloVideoSteam?

    init(delegate: TelloVideoSteam? = nil) {
        self.delegate = delegate
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("[TELLO-VIDEO-] error:", error)
        context.fireErrorCaught(error)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data).data
        let frame = buffer.readBytes(length: buffer.readableBytes)
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.delegate?.telloStream(receive: frame!)
        }
    }
}
