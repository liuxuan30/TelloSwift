# TelloSwift
A DJI Tello(plus EDU) Swift Framework, powered by Apple's [SwiftNIO](https://github.com/apple/swift-nio)

[![Build Status](https://travis-ci.org/liuxuan30/TelloSwift.svg?branch=master)](https://travis-ci.org/liuxuan30/TelloSwift)
![License](https://img.shields.io/github/license/liuxuan30/TelloSwift)

There are already a lot of Tello frameworks in Python, but I don't see a descent one for Apple's platform, especially in Swift. 

Therefore I decided to develop this framework combining latest Swift trend and replaced traditional socket programming fashion with SwiftNIO, an asynchronous event-driven network application framework for rapid development of maintainable high performance protocol.

TelloSwift is built upon SwiftNIO purely in Swift, providing flexible protocols and All-In-One Tello class that you can use to control your Tello drone. It supports both Tello and Tello EDU/IronMan edition.

## Requirement
* Xcode 11 / Swift 5
* iOS >= 12.0
* macOS >= 10.15*

\*For simplicity and Catalyst, I choose 10.15, but the source code itself should support macOS since 10.12, aligned with SwiftNIO's requirement.
