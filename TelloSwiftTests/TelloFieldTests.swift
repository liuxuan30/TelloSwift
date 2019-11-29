//
//  TelloFieldTests.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/11/18.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import XCTest
@testable import TelloSwift

/// Tests started with Mock is using local UDP server,
/// while tests with Tello is against real Tello drone.
class TelloFieldTests: XCTestCase {
    var tello: Tello!

    override func setUp() {
        tello = Tello()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tello.cleanup()
        weak var tmp = tello
        XCTAssertEqual(tmp!.telloAddress, tello.telloAddress)
        tello = nil
        XCTAssertNil(tmp)
        
    }
    
    func testTelloReady() {
        XCTAssertEqual(tello.telloSyncCommand(cmd: "command"), "ok")
    }
}
