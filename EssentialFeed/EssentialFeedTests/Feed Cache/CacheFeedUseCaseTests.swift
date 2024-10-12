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
	
	func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
		store.deleteCachedFeed { [unowned self] error in
			completion(error)
			if error == nil {
				self.store.insert(items, timestamp: self.currentDate())
			}
		}
	}
}

class FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	
	var insertions = [(items: [FeedItem], timestamp: Date)]()
	
	enum ReceivedMessage: Equatable {
		case deleteCachedFeed
		case insert([FeedItem], Date)
	}
	
	private(set) var receivedMessagens = [ReceivedMessage]()
	
	private var deletionCompletions = [DeletionCompletion]()
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		deletionCompletions.append(completion)
		receivedMessagens.append(.deleteCachedFeed)
	}
	
	func completeDeletion(with error: Error, at index: Int = 0) {
		deletionCompletions[index](error)
	}
	
	func completeDeletionSuccessfully(at index: Int = 0) {
		deletionCompletions[index](nil)
	}
	
	func insert(_ items: [FeedItem], timestamp: Date) {
		receivedMessagens.append(.insert(items, timestamp))
	}
}

class CacheFeedUseCaseTests: XCTestCase {
	func test_init_doesNotMessageStoreUponCreation() {
		let store = makeSUT().store
		
		XCTAssertEqual(store.receivedMessagens, [])
	}
	
	func test_save_requestsCacheDeletion() {
		let (sut, store) = makeSUT()
		
		sut.save([uniqueFeedItem(), uniqueFeedItem()]) { _ in }
		
		XCTAssertEqual(store.receivedMessagens, [.deleteCachedFeed])
	}
	
	func test_save_doesNotRequestCacheInsertionOnDeleteError() {
		let items = [uniqueFeedItem(), uniqueFeedItem()]
		let (sut, store) = makeSUT()
		let deletionError = anyNSError()
		
		sut.save(items) { _ in }
		store.completeDeletion(with: deletionError)
		
		XCTAssertEqual(store.receivedMessagens, [.deleteCachedFeed])
	}
	
	func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
		let timestamp = Date()
		let items = [uniqueFeedItem(), uniqueFeedItem()]
		let (sut, store) = makeSUT(currentDate: { timestamp })
		
		sut.save(items) { _ in }
		store.completeDeletionSuccessfully()
		
		XCTAssertEqual(store.receivedMessagens, [.deleteCachedFeed, .insert(items, timestamp)])
	}
	
	func test_save_failsOnDeleteError() {
		let items = [uniqueFeedItem(), uniqueFeedItem()]
		let (sut, store) = makeSUT()
		let deletionError = anyNSError()
		let exp = expectation(description: "Wait for save completion")
		
		var receivedError: Error?
		sut.save(items) { error in
			receivedError = error
			exp.fulfill()
		}
		store.completeDeletion(with: deletionError)
		
		wait(for: [exp], timeout: 1)
		XCTAssertEqual(receivedError as NSError?, deletionError)
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
