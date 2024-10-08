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
		session.dataTask(with: url) { _, _, _ in }.resume()
	}
}

final class URLSessionHTTPClientTests: XCTestCase {
	func test_getFromURL_resumesDataTaskWithURL() {
		let url = URL(string: "http://any-url.com")!
		let task = URLSessionDataTaskSpy()
		let session = URLSesssionSpy()
		
		session.stub(url: url, task: task)
		
		let sut = URLSessionHTTPCLient(session: session)
		
		sut.get(from: url)
		
		XCTAssertEqual(task.resumeCallCount, 1)
	}
	
	//MARK: - Helpers
	
	private class URLSesssionSpy: URLSession {
		var receivedURLs = [URL]()
		private var stubs = [URL: URLSessionDataTask]()
		
		func stub(url: URL, task: URLSessionDataTask) {
			stubs[url] = task
		}
		
		override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
			receivedURLs.append(url)
			
			return stubs[url] ?? FakeURLSessionDataTask()
		}
	}
	
	private class FakeURLSessionDataTask: URLSessionDataTask {
		override func resume() {}
	}
	
	private class URLSessionDataTaskSpy: URLSessionDataTask {
		var resumeCallCount = 0
		
		override func resume() {
			resumeCallCount += 1
		}
	}
}
