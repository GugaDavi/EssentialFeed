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
		let store = FeedStore()
		_ = LocalFeedLoader(store: store)
		
		XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
	}
	
	func test_save_requestsCacheDeletion() {
		let store = FeedStore()
		let sut = LocalFeedLoader(store: store)
		
		sut.save([uniqueFeedItem(), uniqueFeedItem()])
		
		XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
	}
	
	//MARK: - Helpers
	
	private func uniqueFeedItem() -> FeedItem {
		return FeedItem(id: UUID(), imageURL: anyURL())
	}
	
	private func anyURL() -> URL {
		return URL(string: "http://any-url.com")!
	}
}
