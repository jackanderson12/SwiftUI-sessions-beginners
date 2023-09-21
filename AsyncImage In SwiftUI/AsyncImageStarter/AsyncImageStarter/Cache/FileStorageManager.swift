//
//  FiileStorageManager.swift
//  AsyncImageStarter
//
//  Created by Jack Anderson on 9/17/23.
//

import Foundation

final class FileStorageManager {
    
    static let shared = FileStorageManager()
    private let fileManager = FileManager.default
    
    private var cacheFolderURL: URL? {
        fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first
    }
    
    private init() { }
    
    func remove(with fileName: String) {
        
        if let cacheFile = cacheFolderURL?.appendingPathComponent(fileName + ".cache"),
           fileManager.fileExists(atPath: cacheFile.path) {
            
            do {
                try fileManager.removeItem(at: cacheFile)
            } catch {
                #if DEBUG
                print(error)
                #endif
            }
        }
    }
    
    func retrieve(with fileName: String) -> Item? {
        
        guard let cacheFolder = cacheFolderURL else { return nil }
        
        let fileURL = cacheFolder.appendingPathComponent(fileName + ".cache")
        
        guard let data = try? Data(contentsOf: fileURL),
              let item = try? JSONDecoder().decode(Item.self, from: data) else {
            #if DEBUG
            print("Failed to retieve from disk: \(fileName)")
            #endif
            return nil
        }
        #if DEBUG
        print("Retieved from disk: \(fileName)")
        #endif
        return item
    }
    
    func save(_ item: Item) {
        guard let cacheFolder = cacheFolderURL else { return }
        
        let fileURL = cacheFolder.appendingPathComponent(item.name + ".cache")
        
        do {
            let data = try JSONEncoder().encode(item)
            try data.write(to: fileURL)
            #if DEBUG
            print("Saved item to the disk \(item.name)")
            #endif
        } catch {
            #if DEBUG
            print(error)
            #endif
        }
    }
}

extension FileStorageManager {
    struct Item: Codable {
        let name: String
        let data: Data
        let evictionDate: Date
    }
}
