//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 07/10/24.
//

import Foundation

internal final class FeedItemsMapper {
	private struct Root: Decodable {
		let items: [Item]
		
		var feed: [FeedItem] {
			return items.map { $0.item }
		}
	}

	private struct Item: Decodable {
		public let id: UUID
		public let description: String?
		public let location: String?
		public let image: URL
		
		var item: FeedItem {
			return FeedItem(id: id, imageURL: image, description: description, location: location)
		}
	}

	private static var OK_200: Int { return 200 }
	
	internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
		guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(.invalidData)
		}
		
		return .success(root.feed)
	}
}

