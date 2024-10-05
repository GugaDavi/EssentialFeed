//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 02/10/24.
//

import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		
		XCTAssertTrue(client.requestedURLs.isEmpty)
	}
	
	func test_load_requestDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url])
	}
	
	func test_load_requestDataFromURLTwice() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		
		sut.load { _ in }
		sut.load { _ in }
		
		XCTAssertEqual(client.requestedURLs, [url, url])
	}
	
	func test_load_deliversErrorOnClientError() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWithResult: .failure(.connectivity), when: {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		})
	}
	
	func test_load_deliversErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()
		
		let samples = [199, 201, 300, 400, 500]
		
		samples.enumerated().forEach { index, code in
			expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
				client.complete(withStatusCode: code, at: index)
			})
		}
	}
	
	func test_load_deliveriesErrorOn200HTTPResponseWithInvalidJSON() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWithResult: .failure(.invalidData), when: {
			let invalidData = Data("invalid json".utf8)
			client.complete(withStatusCode: 200, data: invalidData)
		})
	}
	
	func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWithResult: .success([]), when: {
			let emtpyListJson = Data("{\"items\": []}".utf8)
			client.complete(withStatusCode: 200, data: emtpyListJson)
		})
	}
	
	func test_load_deliversItemOn200HTTPResponseWithJSONItems() {
		let (sut, client) = makeSUT()
		
		let firstFeedItem = FeedItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
		
		let firstFeedItemJson = [
			"id": firstFeedItem.id.uuidString,
			"image": firstFeedItem.imageURL.absoluteString
		]
		
		let secondFeedItem = FeedItem(
			id: UUID(),
			imageURL: URL(string: "http://a-url.com")!,
			description: "a description",
			location: "a location"
		)
		
		let secondFeedItemJson = [
			"id": secondFeedItem.id.uuidString,
			"image": secondFeedItem.imageURL.absoluteString,
			"description": secondFeedItem.description,
			"location": secondFeedItem.location
		]
		
		let itemsJson = [
			"items": [firstFeedItemJson, secondFeedItemJson]
		]
		
		expect(sut, toCompleteWithResult: .success([firstFeedItem, secondFeedItem]), when: {
			let json = try! JSONSerialization.data(withJSONObject: itemsJson)
			client.complete(withStatusCode: 200, data: json)
		})
	}
	
	//MARK: - Helpers
	
	private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		return (sut: RemoteFeedLoader(url: url, client: client), client: client)
	}
	
	private func expect(
		_ sut: RemoteFeedLoader,
		toCompleteWithResult result: RemoteFeedLoader.Result,
		when action: () -> Void,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		var capturedResults = [RemoteFeedLoader.Result]()
		sut.load { capturedResults.append($0) }
		
		action()
		
		XCTAssertEqual(capturedResults, [result], file: file, line: line)
	}
	
	private class HTTPClientSpy: HTTPClient {
		private var messages = [(url: URL, completion: HTTPClientResponse)]()
		
		var requestedURLs: [URL] {
			return messages.map { $0.url }
		}
		
		func get(from url: URL, completion: @escaping HTTPClientResponse) {
			messages.append((url, completion))
		}
		
		func complete(with error: Error, at index: Int = 0) {
			messages[index].completion(.failure(error))
		}
		
		func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
			let response = HTTPURLResponse(
				url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil
			)!
			messages[index].completion(.success(data, response))
		}
	}
}
