//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gustavo Guedes on 10/10/24.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
	private let store: FeedStore
	
	init(store: FeedStore) {
		self.store = store
	}
	
	func save(_ items: [FeedItem]) {
		store.deleteCachedFeed()
	}
}

class FeedStore {
	var deleteCachedFeedCallCount = 0
	
	func deleteCachedFeed() {
		deleteCachedFeedCallCount += 1
	}
}

class CacheFeedUseCaseTests: XCTestCase {
	func test_init_doesNotDeleteCacheUponCreation() {
		let store = makeSUT().store
		
		XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
	}
	
	func test_save_requestsCacheDeletion() {
		let (sut, store) = makeSUT()
		
		sut.save([uniqueFeedItem(), uniqueFeedItem()])
		
		XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
	}
	
	//MARK: - Helpers
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
		let store = FeedStore()
		let sut = LocalFeedLoader(store: store)
		trackForMemoryLeaks(store, file: file, line: line)
		trackForMemoryLeaks(sut, file: file, line: line)
		return (sut, store)
	}
	
	private func uniqueFeedItem() -> FeedItem {
		return FeedItem(id: UUID(), imageURL: anyURL())
	}
	
	private func anyURL() -> URL {
		return URL(string: "http://any-url.com")!
	}
}
