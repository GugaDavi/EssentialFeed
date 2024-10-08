//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 08/10/24.
//

import XCTest

class URLSessionHTTPCLient {
	private let session: URLSession
	
	init(session: URLSession) {
		self.session = session
	}
	
	func get(from url: URL) {
		session.dataTask(with: url) { _, _, _ in }
	}
}

final class URLSessionHTTPClientTests: XCTestCase {
	func test() {
		let url = URL(string: "http://any-url.com")!
		let session = URLSesssionSpy()
		let sut = URLSessionHTTPCLient(session: session)
		
		sut.get(from: url)
		
		XCTAssertEqual(session.receivedURLs, [url])
	}
	
	//MARK: - Helpers
	
	private class URLSesssionSpy: URLSession {
		var receivedURLs = [URL]()
		
		override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
			receivedURLs.append(url)
			
			return FakeURLSessionDataTask()
		}
	}
	
	private class FakeURLSessionDataTask: URLSessionDataTask {}
}
