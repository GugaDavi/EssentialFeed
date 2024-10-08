//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 08/10/24.
//

import XCTest
import EssentialFeed

class URLSessionHTTPCLient {
	private let session: URLSession
	
	init(session: URLSession) {
		self.session = session
	}
	
	func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
		session.dataTask(with: url) { _, _, e in
			if let error = e {
				completion(.failure(error))
			}
		}.resume()
	}
}

final class URLSessionHTTPClientTests: XCTestCase {
	func test_getFromURL_resumesDataTaskWithURL() {
		let url = URL(string: "http://any-url.com")!
		let task = URLSessionDataTaskSpy()
		let session = URLSesssionSpy()
		
		session.stub(url: url, task: task)
		
		let sut = URLSessionHTTPCLient(session: session)
		
		sut.get(from: url) { _ in }
		
		XCTAssertEqual(task.resumeCallCount, 1)
	}
	
	func test_getFromURL_failsOnRequestError() {
		let url = URL(string: "http://any-url.com")!
		let error = NSError(domain: "any error", code: 1)
		let session = URLSesssionSpy()
		
		session.stub(url: url, error: error)
		
		let sut = URLSessionHTTPCLient(session: session)
		
		let exp = expectation(description: "Wait for completion")
		
		sut.get(from: url) { result in
			switch result {
			case let .failure(receivedError as NSError):
				XCTAssertEqual(receivedError, error)
			default:
				XCTFail("Expected failure with error \(error), got \(result) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	//MARK: - Helpers
	
	private class URLSesssionSpy: URLSession {
		private var stubs = [URL: Stub]()
		
		private struct Stub {
			let task: URLSessionDataTask
			let error: Error?
		}
		
		func stub(url: URL, task: URLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
			stubs[url] = Stub(task: task, error: error)
		}
		
		override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
			guard let stub = stubs[url] else {
				fatalError("Couln't find stub for \(url)")
			}
			
			completionHandler(nil, nil, stub.error)
			
			return stub.task
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
