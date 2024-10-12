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
	private let currentDate: () -> Date
	
	init(store: FeedStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}
	
	func save(_ items: [FeedItem]) {
		store.deleteCachedFeed { [unowned self] error in
			if error == nil {
				self.store.insert(items, timestamp: self.currentDate())
			}
		}
	}
}

class FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	
	var deleteCachedFeedCallCount = 0
	var insertions = [(items: [FeedItem], timestamp: Date)]()
	
	private var deletionCompletions = [DeletionCompletion]()
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		deleteCachedFeedCallCount += 1
		deletionCompletions.append(completion)
	}
	
	func completeDeletion(with error: Error, at index: Int = 0) {
		deletionCompletions[index](error)
	}
	
	func completeDeletionSuccessfully(at index: Int = 0) {
		deletionCompletions[index](nil)
	}
	
	func insert(_ items: [FeedItem], timestamp: Date) {
		insertions.append((items, timestamp))
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
	
	func test_save_doesNotRequestCacheInsertionOnDeleteError() {
		let items = [uniqueFeedItem(), uniqueFeedItem()]
		let (sut, store) = makeSUT()
		let deletionError = anyNSError()
		
		sut.save(items)
		store.completeDeletion(with: deletionError)
		
		XCTAssertEqual(store.insertions.count, 0)
	}
	
	func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
		let timestemp = Date()
		let items = [uniqueFeedItem(), uniqueFeedItem()]
		let (sut, store) = makeSUT(currentDate: { timestemp })
		
		sut.save(items)
		store.completeDeletionSuccessfully()
		
		XCTAssertEqual(store.insertions.first?.items, items)
		XCTAssertEqual(store.insertions.first?.timestamp, timestemp)
	}

	
	//MARK: - Helpers
	
	private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStore) {
		let store = FeedStore()
		let sut = LocalFeedLoader(store: store, currentDate: currentDate)
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
	
	private func anyNSError() -> NSError {
		return NSError(domain: "any error", code: 0)
	}
}
