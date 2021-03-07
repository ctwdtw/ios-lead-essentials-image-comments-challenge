//
//  ImageCommentsLoader.swift
//  EssentialFeed
//
//  Created by Paul Lee on 2021/3/7.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

public class ImageCommentsLoader {
	private let client: HTTPClient
	private let url: URL
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	
	struct RemoteImageComment: Codable {
		
	}
	
	struct RemoteImageComments: Codable {
		let items: [RemoteImageComment]
	}
	
	public typealias LoadImageCommentsCompletion = (LoadImageCommentsResult) -> Void
	public typealias LoadImageCommentsResult = Result<[ImageComment], Error>
	public func loadImageComments(completion: @escaping LoadImageCommentsCompletion) {
		client.get(from: url) { (result) in
			switch result {
			case .success((let data, let response)):
				guard response.statusCode == 200 else {
					completion(.failure(Error.invalidData))
					return
				}
				
				do {
					let comments = try JSONDecoder().decode(RemoteImageComments.self, from: data)
					let imageComments = comments.items.map { _ in ImageComment() }
					completion(.success(imageComments))
					
				} catch {
					completion(.failure(.invalidData))
				}
				
			case .failure(_):
				completion(.failure(Error.connectivity))
			}
		}
	}
}
