//
//  MockTelloHandlerTests.swift
//  TelloSwiftTests
//
//  Created by Xuan Liu on 2019/11/18.
//  Copyright © 2019 Xuan Liu. All rights reserved.
//

import XCTest
@testable import TelloSwift

/// Tests started with Mock is using local UDP server,
/// while tests with Tello is against real Tello drone.
class MockTelloHandlerTests: XCTestCase {
    var telloServer: HandlerTestServer!
    var tello: Tello!

    override func setUp() {
        tello = Tello()
        
        // mock address
        tello.telloAddress = "127.0.0.1"
        
        // mock as Tello
        telloServer = HandlerTestServer(addr: "127.0.0.1", port: 8889)
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

    func testMockSyncCommand() {
        XCTAssertEqual(tello.telloSyncCommand(cmd: "TelloSyncCmd"), "TelloSyncCmd")
    }
    
    func testMockAsyncCommand() {
        let cmd = "TelloAsyncCommand"
        let expect = XCTestExpectation()

        tello.telloAsyncCommand(cmd: cmd, successHandler: { s in
            XCTAssertEqual(s, cmd)
            expect.fulfill()
        }, failureHandler: nil)
        wait(for: [expect], timeout: 3)
    }
    
    func testMockNestAsyncSync() {
        let expect = XCTestExpectation()
        
        tello.telloAsyncCommand(cmd: "async", successHandler: { s in
            XCTAssertEqual(s, "async")
            XCTAssertEqual(self.tello.telloSyncCommand(cmd: "sync"), "sync")
            XCTAssertEqual(self.tello.telloSyncCommand(cmd: "syncAgain"), "syncAgain")
            expect.fulfill()
        }, failureHandler: nil)
        wait(for: [expect], timeout: 3)
    }
    
    func testMockNestTripleAsync() {
        let expect = XCTestExpectation()
        
        tello.telloAsyncCommand(cmd: "async", successHandler: { s in
            XCTAssertEqual(s, "async")
            
            self.tello.telloAsyncCommand(cmd: "doubleAsync", successHandler: { doubleAsync in
                XCTAssertEqual(doubleAsync, "doubleAsync")
                self.tello.telloAsyncCommand(cmd: "tripleAsync", successHandler: { triple  in
                    XCTAssertEqual(triple, "tripleAsync")
                    expect.fulfill()
                }, failureHandler: nil)
            }, failureHandler: nil)
            
        }, failureHandler: nil)
        
        wait(for: [expect], timeout: 3)
    }
    
    func testMockNestAsyncSyncAsync() {
        let expect = XCTestExpectation()
        
        tello.telloAsyncCommand(cmd: "async", successHandler: { s in
            XCTAssertEqual(s, "async")
            XCTAssertEqual(self.tello.telloSyncCommand(cmd: "sync"), "sync")
            XCTAssertEqual(self.tello.telloSyncCommand(cmd: "syncAgain"), "syncAgain")
            
            self.tello.telloAsyncCommand(cmd: "doubleAsync", successHandler: { doubleAsync in
                XCTAssertEqual(doubleAsync, "doubleAsync")
                expect.fulfill()
            }, failureHandler: nil)
            
        }, failureHandler: nil)
        
        wait(for: [expect], timeout: 3)
    }
    
    func testMockNilHandler() {
        // no expeaction, just peacefully ends if all is well
        tello.telloAsyncCommand(cmd: "async", successHandler: { s in
            XCTAssertEqual(s, "async")
            
            self.tello.telloAsyncCommand(cmd: "doubleAsync", successHandler: { doubleAsync in
                XCTAssertEqual(doubleAsync, "doubleAsync")
                
                self.tello.telloAsyncCommand(cmd: "tripleAsync", successHandler:nil, failureHandler: nil)
                
            }, failureHandler: nil)
            
        }, failureHandler: nil)
        sleep(2)
    }

    func testFailureHandler() {
        let expect = XCTestExpectation()

        tello.asyncSendCommand(cmd: "async", remoteAddr: "256.0.0.1", remotePort: 80, successHandler: {
            XCTAssertNil($0)
        }) {
            XCTAssertNotNil($0)
            expect.fulfill()
        }

        wait(for: [expect], timeout: 3)
    }

    func testMockInOneTello() {
        testMockSyncCommand()
        testMockAsyncCommand()
        testMockNestAsyncSync()
        testMockNestTripleAsync()
        testMockNilHandler()
        testMockNestAsyncSyncAsync()
        testFailureHandler()
    }
}
