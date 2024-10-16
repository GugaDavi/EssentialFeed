//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 15/10/24.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
	private struct Cache: Codable {
		let feed: [CodableFeedImage]
		let timestamp: Date
		
		var localFeed: [LocalFeedImage] {
			return feed.map { $0.local }
		}
	}
	
	private struct CodableFeedImage: Codable {
		private let id: UUID
		private let description: String?
		private let location: String?
		private let url: URL
		
		init (_ image: LocalFeedImage) {
			id = image.id
			description = image.description
			location = image.location
			url = image.url
		}
		
		var local: LocalFeedImage {
			return LocalFeedImage(id: id, url: url, description: description, location: location)
		}
	}
	
	private let storeURL: URL
	
	init(storeURL: URL) {
		self.storeURL = storeURL
	}
	
	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
		let encoder = JSONEncoder()
		let encoded = try! encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp))
		try! encoded.write(to: storeURL)
		completion(nil)
	}
	
	func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
		guard let data = try? Data(contentsOf: storeURL) else {
			return completion(.empty)
		}
		
		let decoder = JSONDecoder()
		let cache = try! decoder.decode(Cache.self, from: data)
		completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
	}
}

final class CodableFeedStoreTests: XCTestCase {
	override func setUp() {
		super.setUp()
		
		setupEmptyStoreState()
	}
	
	override func tearDown() {
		super.tearDown()
		
		undoStoreSideEffects()
	}
	
	func test_retrieve_deliversEmptyData() {
		let sut = makeSUT()
		
		expect(sut, toRetrieve: .empty)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { firstResult in
			sut.retrieve { secondResult in
				switch (firstResult, secondResult) {
				case (.empty, .empty):
					break
				default:
					XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
				}
				
				exp.fulfill()
			}
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	func test_retrieve_afterInsertingToEmptyCache_deliversInsertedValues() {
		let sut = makeSUT()
		let feed = uniqueImageFeed().local
		let timestamp = Date()
		
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.insert(feed, timestamp: timestamp) { insertionError in
			XCTAssertNil(insertionError)
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
		expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		let feed = uniqueImageFeed().local
		let timestamp = Date()
		
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.insert(feed, timestamp: timestamp) { insertionError in
			XCTAssertNil(insertionError)
			
			sut.retrieve { firstResult in
				sut.retrieve { secondResult in
					switch (firstResult, secondResult) {
					case let (.found(firstFoundFeed, firstFoundTimestamp), .found(secondFoundFeed, secondFoundTimestamp)):
						XCTAssertEqual(firstFoundFeed, feed)
						XCTAssertEqual(firstFoundTimestamp, timestamp)
						
						XCTAssertEqual(secondFoundFeed, feed)
						XCTAssertEqual(secondFoundTimestamp, timestamp)
					default:
						XCTFail("Expected retrieving twice from non empty cache to deliver same found result with feed \(feed) and timestamp \(timestamp), got \(firstResult) and \(secondResult) instead")
					}
					
					exp.fulfill()
				}
			}
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	//MARK: - Helpers
	
	private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrievalcachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { retrievedResult in
			switch (expectedResult, retrievedResult) {
			case (.empty, .empty):
				break
			case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
				XCTAssertEqual(expectedFeed, retrievedFeed)
				XCTAssertEqual(expectedTimestamp, retrievedTimestamp)
			default:
				XCTFail("Expected to retreive \(expectedResult), got \(retrievedResult) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
	}
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
		let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	private func testSpecificStoreURL() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store")
	}
	
	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL())
	}
	
	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}
	
	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}
}
