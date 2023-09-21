//
//  ImageRetriever.swift
//  AsyncImageStarter
//
//  Created by Jack Anderson on 9/16/23.
//

import Foundation

struct ImageRetriever {
    func fetch(_ imgURL: String) async throws -> Data {
        guard let url = URL(string: imgURL) else {
            throw RetrieverError.invalidURL
        }
        
        let (data, _) =  try await URLSession.shared.data(from: url)
        return data
    }
}

private extension ImageRetriever {
    enum RetrieverError: Error {
        case invalidURL
    }
}
