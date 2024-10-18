//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Gustavo Guedes on 07/10/24.
//

import Foundation

public typealias HTTPClientResponse = (HTTPClientResult) -> Void

public enum HTTPClientResult {
	case success(Data, HTTPURLResponse)
	case failure(Error)
}

public protocol HTTPClient {
	/// The completion handler can be invoked in any thread.
	/// Clients are responsible to dispatch to appropriate threads, if needed.
	func get(from url: URL, completion: @escaping HTTPClientResponse)
}
