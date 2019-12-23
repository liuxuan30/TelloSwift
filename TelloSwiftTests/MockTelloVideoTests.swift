//
//  MockTelloVideoTests.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/12/20.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import XCTest
@testable import TelloSwift

/// Tests started with Mock is using local UDP server,
/// while tests with Tello is against real Tello drone.
class MockTelloVideoTests: XCTestCase, TelloVideoSteam {

    var telloServer: TelloSimulator!
    var tello: Tello!
    var streamData: Data?

    func telloStream(receive frame: Data?) {
        streamData = frame
    }

    override func setUp() {
        tello = Tello()

        // mock address
        tello.telloAddress = "127.0.0.1"

        // mock as Tello
        telloServer = TelloSimulator(addr: "127.0.0.1", port: 8889)
        XCTAssertNoThrow(try telloServer!.start())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        // cleanup the socket and event loop resources, if not called, UT would fail
        tello.cleanup()
        telloServer.stop()

        weak var tmpGroup = tello.group
        tello = nil
        telloServer = nil
        XCTAssertNil(tmpGroup) // check if tello has called deinit
    }

    func testStreamDelegate() {
        let expect = XCTestExpectation()
        tello.videoDelegate = self
        telloServer.sendStream()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            XCTAssertEqual(String(data: self.streamData!, encoding: .utf8), "HelloThisIsVideoStreamTest")
            expect.fulfill()
        })

        wait(for: [expect], timeout: 3)
    }

}
