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
	
	public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
		store.deleteCachedFeed { [weak self] error in
			guard let self = self else { return }
			
			if let cacheDeletionError = error {
				completion(cacheDeletionError)
			} else {
				self.cache(items, with: completion)
			}
		}
	}
	
	private func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
		store.insert(items.toLocal(), timestamp: currentDate(), completion: { [weak self] error in
			guard self != nil else { return }
			completion(error)
		})
	}
}

private extension Array where Element == FeedItem {
	func toLocal() -> [LocalFeedItem] {
		return map { LocalFeedItem(id: $0.id, imageURL: $0.imageURL, description: $0.description, location: $0.location) }
	}
}
