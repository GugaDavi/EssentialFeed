//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation

public final class LocalFeedLoader {
	private let store: FeedStore
	private let currentDate: () -> Date
	
	public init(store: FeedStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}
	
	public typealias SaveResult = Error?
	
	public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
		store.deleteCachedFeed { [weak self] error in
			guard let self = self else { return }
			
			if let cacheDeletionError = error {
				completion(cacheDeletionError)
			} else {
				self.cache(feed, with: completion)
			}
		}
	}
	
	public func load() {
		store.retrieve()
	}
	
	private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
		store.insert(feed.toLocal(), timestamp: currentDate(), completion: { [weak self] error in
			guard self != nil else { return }
			completion(error)
		})
	}
}

private extension Array where Element == FeedImage {
	func toLocal() -> [LocalFeedImage] {
		return map { LocalFeedImage(id: $0.id, url: $0.url, description: $0.description, location: $0.location) }
	}
}
