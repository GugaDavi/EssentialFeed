//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation

public protocol FeedStore {
	typealias DeletionCompletion = (Error?) -> Void
	typealias InsertionCompletion = (Error?) -> Void
	
	func deleteCachedFeed(completion: @escaping DeletionCompletion)
	func insert(_ items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalFeedItem: Equatable {
	public let id: UUID
	public let description: String?
	public let location: String?
	public let imageURL: URL
	
	public init(id: UUID, imageURL: URL, description: String? = nil, location: String? = nil) {
		self.id = id
		self.description = description
		self.location = location
		self.imageURL = imageURL
	}
}
