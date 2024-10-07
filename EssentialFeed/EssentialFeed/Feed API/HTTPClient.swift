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
	func get(from url: URL, completion: @escaping HTTPClientResponse)
}
