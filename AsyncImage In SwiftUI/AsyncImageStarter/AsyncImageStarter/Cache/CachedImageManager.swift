//
//  CachedImageManager.swift
//  AsyncImageStarter
//
//  Created by Jack Anderson on 9/16/23.
//

import Foundation

final class CachedImageManager: ObservableObject {
    
    @Published private(set) var currentState: CurrentState?
    
    private let imageRetriever = ImageRetriever()
    
    @MainActor
    func load(_ item: (name: String, url: String), cache: ImageCache = .shared) async {
        
        if let imageData = cache.object(forkey: item.name as NSString) {
            self.currentState = .success(data: imageData)
            #if DEBUG
            print("Fetching image from the cache: \(item.name)")
            #endif
            return
        }
        
        if let diskCacheItem = FileStorageManager.shared.retrieve(with: item.name),
            Date.now < diskCacheItem.evictionDate {
            
            #if DEBUG
            print("Storing image in memeory from disk: \(diskCacheItem.name)")
            #endif
            cache.set(object: diskCacheItem.data as NSData,
                      forkey: diskCacheItem.name as NSString)
            
            self.currentState = .success(data: diskCacheItem.data)
            return
        }
        
        FileStorageManager.shared.remove(with: item.name)
        
        self.currentState = .loading
        
        do {
            let data = try await imageRetriever.fetch(item.url)
            self.currentState = .success(data: data)
            cache.set(object: data as NSData, 
                      forkey: item.name as NSString)
            if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) {
                FileStorageManager.shared.save(.init(name: item.name, data: data, evictionDate: tomorrow))
            }
            #if DEBUG
            print("Caching image: \(item.name)")
            #endif
        } catch {
            currentState = .failed(error: error)
        }
    }
}

extension CachedImageManager {
    enum CurrentState {
        case loading
        case failed(error: Error)
        case success(data: Data)
    }
}

extension CachedImageManager.CurrentState: Equatable {
    static func == (lhs: CachedImageManager.CurrentState,
                    rhs: CachedImageManager.CurrentState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (let .failed(error: lhsError), let .failed(error: rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (let .success(data: lhsData), let .success(data: rhsData)):
            return lhsData == rhsData
        default:
            return false
        }
    }
}
