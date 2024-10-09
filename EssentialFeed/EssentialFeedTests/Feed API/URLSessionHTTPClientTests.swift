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
	
	init(session: URLSession = .shared) {
		self.session = session
	}
	
	private struct UnexpectedValuesRepresentation: Error {}
	
	func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
		session.dataTask(with: url) { _, _, e in
			if let error = e {
				completion(.failure(error))
			} else {
				completion(.failure(UnexpectedValuesRepresentation()))
			}
		}.resume()
	}
}

final class URLSessionHTTPClientTests: XCTestCase {
	override func setUp() {
		super.setUp()
		
		URLProtocolStub.startInterceptingRequests()
	}
	
	override func tearDown() {
		super.tearDown()
		
		URLProtocolStub.stopInterceptingRequests()
	}
	
	func test_getFromURL_performsGETRequestWithURL() {
		let url = anyURL()
		let expectation = expectation(description: "Wait for request")
		
		URLProtocolStub.observeRequests { request in
			XCTAssertEqual(request.url, url)
			XCTAssertEqual(request.httpMethod, "GET")
			
			expectation.fulfill()
		}
		
		makeSUT().get(from: url) { _ in }
		
		wait(for: [expectation], timeout: 1)
	}
	
	func test_getFromURL_failsOnRequestError() {
		let requestError = NSError(domain: "any error", code: 1)
		
		let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
		
		XCTAssertEqual((receivedError as NSError?)?.domain, requestError.domain)
		XCTAssertEqual((receivedError as NSError?)?.code, requestError.code)
	}
	
	func test_getFromURL_failsOnAllNilValues() {
		XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
	}
	
	//MARK: - Helpers
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPCLient {
		let sut = URLSessionHTTPCLient()
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	private func anyURL() -> URL {
		return URL(string: "http://any-url.com")!
	}
	
	private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error?  {
		URLProtocolStub.stub(data: data, response: response, error: error)
		let sut = makeSUT(file: file, line: line)
		let exp = expectation(description: "Wait for completion")
		var receivedError: Error?
		
		sut.get(from: anyURL()) { result in
			switch result {
			case let .failure(error):
				receivedError = error
			default:
				XCTFail("Expected failure, got \(result) instead", file: file, line: line)
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
		return receivedError
	}
	
	private class URLProtocolStub: URLProtocol {
		private static var stub: Stub?
		private static var requestObserver: ((URLRequest) -> Void)?
		
		private struct Stub {
			let data: Data?
			let response: URLResponse?
			let error: Error?
		}
		
		static func stub(data: Data?, response: URLResponse?, error: Error?) {
			stub = Stub(data: data, response: response, error: error)
		}
		
		static func observeRequests(observer: @escaping (URLRequest) -> Void) {
			requestObserver = observer
		}
		
		static func startInterceptingRequests() {
			URLProtocol.registerClass(URLProtocolStub.self)
		}
		
		static func stopInterceptingRequests() {
			URLProtocol.unregisterClass(URLProtocolStub.self)
			stub = nil
			requestObserver = nil
		}
		
		override class func canInit(with request: URLRequest) -> Bool {
			requestObserver?(request)
			return true
		}
		
		override class func canonicalRequest(for request: URLRequest) -> URLRequest {
			return request
		}
		
		override func startLoading() {
			if let data = URLProtocolStub.stub?.data {
				client?.urlProtocol(self, didLoad: data)
			}
			
			if let response = URLProtocolStub.stub?.response {
				client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			}
			
			if let error = URLProtocolStub.stub?.error {
				client?.urlProtocol(self, didFailWithError: error)
			}
			
			client?.urlProtocolDidFinishLoading(self)
		}
		
		override func stopLoading() {}
	}
}
