//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest

protocol HTTPClient {
	func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
	func get(from url: URL) {
		requestedURL = url
	}
	
	var requestedURL: URL?
}

class RemoteFeedLoader {
	let client: HTTPClient
	
	init(client: HTTPClient) {
		self.client = client
	}
	
	func load() {
		client.get(from: URL(string: "https://a-url.com")!)
	}
}

final class RemoteFeedLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let client = HTTPClientSpy()
		_ = RemoteFeedLoader(client: client)
		
		XCTAssertNil(client.requestedURL)
	}

	func test_load_requestDataFromURL() {
		let client = HTTPClientSpy()
		let sut = RemoteFeedLoader(client: client)
		
		sut.load()
		
		XCTAssertNotNil(client.requestedURL)
	}
}
