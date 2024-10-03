//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest

class HTTPClient {
	static var shared = HTTPClient()
	
	var requestURL: URL?
	
	func get(from url: URL) {
	}
}

class HTTPClientSpy: HTTPClient {
	override func get(from url: URL) {
		requestURL = url
	}
}

class RemoteFeedLoader {
	func load() {
		HTTPClient.shared.requestURL = URL(string: "https://a-url.com")
	}
}

final class RemoteFeedLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let client = HTTPClientSpy()
		HTTPClient.shared = client
		let sut = RemoteFeedLoader()
		
		XCTAssertNil(client.requestURL)
	}

	func test_load_requestDataFromURL() {
		let client = HTTPClientSpy()
		HTTPClient.shared = client
		let sut = RemoteFeedLoader()
		
		sut.load()
		
		XCTAssertNotNil(client.requestURL)
	}
}
