//
//  ImageComment.swift
//  EssentialFeed
//
//  Created by Paul Lee on 2021/3/7.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
public struct ImageComment: Equatable {
	public let id: UUID
	public let message: String
	public let createAt: Date
	public let author: String
	
	public init(
		id: UUID,
		message: String,
		createAt: Date,
		author: String
	) {
		self.id = id
		self.message = message
		self.createAt = createAt
		self.author = author
	}
}


