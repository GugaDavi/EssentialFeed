//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 14/10/24.
//

import Foundation

struct RemoteFeedItem: Decodable {
	let id: UUID
	let description: String?
	let location: String?
	let image: URL
}
