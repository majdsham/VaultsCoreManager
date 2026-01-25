//
//  VaultsStorage.swift
//  VaultsCoreManager
//
//  Created by Majd Aldeyn Ez Alrejal on 12/1/25.
//

import Foundation
// test push
actor VaultsStorage {
    private let fileName = "vaults.json"
    
    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("VaultData").appendingPathComponent(fileName)
    }
    
    func save(_ vaults: [Vault]) throws {
        let data = try JSONEncoder().encode(vaults)
        try data.write(to: fileURL)
    }
    
    func load() -> [Vault] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Vault].self, from: data)
        } catch {
            print("Error loading vaults: \(error)")
            return []
        }
    }
}
