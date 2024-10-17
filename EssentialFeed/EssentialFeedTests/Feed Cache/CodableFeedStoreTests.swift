//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 15/10/24.
//

import XCTest
import EssentialFeed

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
		
		expect(sut, toRetrieveTwice: .empty)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
		let sut = makeSUT()
		let feed = uniqueImageFeed().local
		let timestamp = Date()
		
		insert((feed, timestamp), to: sut)
		
		expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
		let sut = makeSUT()
		let feed = uniqueImageFeed().local
		let timestamp = Date()
		
		insert((feed, timestamp), to: sut)
		
		expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_retrieve_deliversFailureOnRetrievalError() {
		let storeURL = testSpecificStoreURL()
		let sut = makeSUT(storeURL: storeURL)
		
		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
		
		expect(sut, toRetrieve: .failure(anyNSError()))
	}
	
	func test_retrieve_hasNoSideEffectsOnFailure() {
		let storeURL = testSpecificStoreURL()
		let sut = makeSUT(storeURL: storeURL)
		
		try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)
		
		expect(sut, toRetrieveTwice: .failure(anyNSError()))
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() {
		let sut = makeSUT()
		
		let firstInsertionError = insert((uniqueImageFeed().local, Date()), to: sut)
		XCTAssertNil(firstInsertionError)
		
		let latestFeed = uniqueImageFeed().local
		let latestTimestamp = Date()
		let latestInserionError = insert((latestFeed, latestTimestamp), to: sut)
		XCTAssertNil(latestInserionError)
		
		expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
	}
	
	func test_insert_deliversErrorOnInsertionError() {
		let invalidStoreURL = URL(string: "invalid-store-url")
		let sut = makeSUT(storeURL: invalidStoreURL)
		let feed = uniqueImageFeed().local
		let timestamp = Date()
		
		let insertionError = insert((feed, timestamp), to: sut)
		
		XCTAssertNotNil(insertionError)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() {
		let sut = makeSUT()
		
		let deletionError = deleteCache(from: sut)
		
		XCTAssertNil(deletionError)
		expect(sut, toRetrieve: .empty)
	}
	
	func test_delete_emptiesPrevioslyInsertedCache() {
		let sut = makeSUT()
		insert((uniqueImageFeed().local, Date()), to: sut)
		
		let deletionError = deleteCache(from: sut)
		
		XCTAssertNil(deletionError)
		expect(sut, toRetrieve: .empty)
	}
	
	func test_delete_deliversErrorOnDeletionError() {
		let noDeletePermissionURL = cachesDirector()
		let sut = makeSUT(storeURL: noDeletePermissionURL)
		
		let deletionError = deleteCache(from: sut)
		
		XCTAssertNotNil(deletionError)
	}
	
	//MARK: - Helpers
	
	private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrievalcachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
		expect(sut, toRetrieve: expectedResult, file: file, line: line)
		expect(sut, toRetrieve: expectedResult, file: file, line: line)
	}
	
	private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrievalcachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
		let exp = expectation(description: "Wait for cache retrieval")
		
		sut.retrieve { retrievedResult in
			switch (expectedResult, retrievedResult) {
			case (.empty, .empty), (.failure, .failure):
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
	
	@discardableResult
	private func deleteCache(from sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache deletion")
		var deletionError: Error? = nil
		sut.deleteCachedFeed { error in
			deletionError = error
			exp.fulfill()
		}
		wait(for: [exp], timeout: 1)
		return deletionError
	}
	
	@discardableResult
	private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) -> Error? {
		let exp = expectation(description: "Wait for cache insertion")
		
		var receivedError: Error? = nil
		sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
			receivedError = insertionError
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1)
		return receivedError
	}
	
	private func makeSUT(storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
		let sut = CodableFeedStore(storeURL: storeURL ?? testSpecificStoreURL())
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	private func testSpecificStoreURL() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store")
	}
	
	private func cachesDirector() -> URL {
		return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
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
