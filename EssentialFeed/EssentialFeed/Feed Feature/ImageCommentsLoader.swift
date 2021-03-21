//
//  ImageCommentsLoader.swift
//  EssentialFeed
//
//  Created by Paul Lee on 2021/3/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
public protocol ImageCommentLoaderTask {
	func cancel()
}

public protocol ImageCommentsLoader {
	typealias LoadImageCommentsResult = Result<[ImageComment], Error>
	typealias LoadImageCommentsCompletion = (LoadImageCommentsResult) -> Void
	
	func loadImageComments(completion: @escaping LoadImageCommentsCompletion) -> ImageCommentLoaderTask
}
