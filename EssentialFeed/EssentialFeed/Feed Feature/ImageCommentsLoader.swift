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
	
	struct RemoteImageComment: Decodable {
		let id: String
		let message: String
		let createAt: String
		let author: RemoteUser
		
		private enum CodingKeys: String, CodingKey {
			case id, message, author
			case createAt = "create_at"
		}
	}
	
	struct RemoteUser: Decodable {
		let username: String
	}
	
	struct RemoteImageComments: Decodable {
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
					let imageComments = comments.items.map { $0.toModel() }
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

private extension ImageCommentsLoader.RemoteImageComment {
	func toModel() -> ImageComment {
		let uuid = UUID(uuidString: id)!
		let date = ISO8601DateFormatter().date(from: createAt)!
		return ImageComment(
			id: uuid,
			message: message,
			createAt: date,
			author: author.username
		)
	}
}
