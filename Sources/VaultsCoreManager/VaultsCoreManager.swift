//
//  VaultsCoreManager.swift
//  VaultsCoreManager
//
//  Created by Majd Aldeyn Ez Alrejal on 12/1/25.
//

import Foundation

public actor VaultsCoreManager: ObservableObject {
    private var vaults: [Vault] = []
    private let storage: VaultsStorage
    private let parentFolderURL: URL
    
    private var loadTask: Task<[Vault], Never>?
    
    public init(parentFolder: URL) {
        self.parentFolderURL = parentFolder
        let storage = VaultsStorage()
        self.storage = storage
        loadTask = Task {
            await storage.load()
        }
        Task {
            await ensureLoaded()
        }
    }
    
    private func ensureLoaded() async {
        if let task = loadTask {
            self.vaults = await task.value
            self.loadTask = nil
        }
    }
    
    // MARK: - Core Functionality
    
    public func addVault() async throws -> Vault {
        await ensureLoaded()
        let newVault = Vault()
        
        // Create folder
        try createFolder(for: newVault.id)
        
        vaults.append(newVault)
        try await storage.save(vaults)
        
        return newVault
    }
    
    public func deleteVault(_ vault: Vault) async -> Result<Void, Error> {
        return await deleteVault(byId: vault.id)
    }
    
    public func deleteVault(byId id: UUID) async -> Result<Void, Error> {
        await ensureLoaded()
        guard let index = vaults.firstIndex(where: { $0.id == id }) else {
            return .failure(VaultError.vaultNotFound)
        }
        
        do {
            // Delete folder
            try deleteFolder(for: id)
            
            vaults.remove(at: index)
            try await storage.save(vaults)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Passcode Management
    
    public func getVault(passcode: String) -> Vault? {
        return vaults.first(where: { $0.passcode == passcode })
    }
    
    public func setPasscode(id: UUID, new: String) async -> Result<Void, Error> {
        await ensureLoaded()
        guard let index = vaults.firstIndex(where: { $0.id == id }) else {
            return .failure(VaultError.vaultNotFound)
        }
        
        // Check uniqueness
        if vaults.contains(where: { $0.passcode == new }) {
            return .failure(VaultError.passcodeAlreadyExists)
        }
        
        var vault = vaults[index]
        vault.passcode = new
        vaults[index] = vault
        
        do {
            try await storage.save(vaults)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    public func changePasscode(old: String, new: String) async -> Result<Void, Error> {
        await ensureLoaded()
        guard let index = vaults.firstIndex(where: { $0.passcode == old }) else {
            return .failure(VaultError.vaultNotFound)
        }
        
        // Check uniqueness
        if vaults.contains(where: { $0.passcode == new }) {
            return .failure(VaultError.passcodeAlreadyExists)
        }
        
        var vault = vaults[index]
        vault.passcode = new
        vaults[index] = vault
        
        do {
            try await storage.save(vaults)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    public func removePasscode(id: UUID) async throws -> Vault {
        await ensureLoaded()
        guard let index = vaults.firstIndex(where: { $0.id == id }) else {
            throw VaultError.vaultNotFound
        }
        
        var vault = vaults[index]
        vault.passcode = nil
        vaults[index] = vault
        
        try await storage.save(vaults)
        return vault
    }
    
    public func validatePasscodeUniqueness(_ passcode: String) -> Bool {
        return !vaults.contains(where: { $0.passcode == passcode })
    }
    
    // MARK: - Phone Number Management
    
    public func updatePhoneNumber(id: UUID, number: String) async throws -> Vault {
        await ensureLoaded()
        guard let index = vaults.firstIndex(where: { $0.id == id }) else {
            throw VaultError.vaultNotFound
        }
        
        var vault = vaults[index]
        vault.phoneNumber = number
        vaults[index] = vault
        
        try await storage.save(vaults)
        return vault
    }
    
    public func getVault(phoneNumber: String) -> Vault? {
        return vaults.first(where: { $0.phoneNumber == phoneNumber })
    }
    
    // MARK: - Helper Methods
    private func createFolder(
        for id: UUID,
    ) throws {
        let folderURL = parentFolderURL.appendingPathComponent(id.uuidString, isDirectory: true)

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )
        }
    }
    
    private func deleteFolder(for id: UUID) throws {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsDirectory.appendingPathComponent(id.uuidString)
        
        if FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.removeItem(at: folderURL)
        }
    }
}

public enum VaultError: Error {
    case vaultNotFound
    case passcodeAlreadyExists
}
