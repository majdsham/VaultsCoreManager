//
//  VaultsCoreTests.swift
//  VaultsCoreManager
//
//  Created by Majd Aldeyn Ez Alrejal on 12/1/25.
//

import XCTest
@testable import VaultsCoreManager

final class VaultsCoreTests: XCTestCase {
    var manager: VaultsCoreManager!
    
    override func setUp() async throws {
        manager = VaultsCoreManager()
    }
    
    func testAddVault() async throws {
        let vault = try await manager.addVault()
        XCTAssertNotNil(vault.id)
        
        // Check if folder exists
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderURL = documentsDirectory.appendingPathComponent(vault.id.uuidString)
        XCTAssertTrue(FileManager.default.fileExists(atPath: folderURL.path))
        
        // Cleanup
        _ = await manager.deleteVault(vault)
    }
    
    func testPasscodeManagement() async throws {
        let vault = try await manager.addVault()
        
        // Set initial passcode
        let setRes = await manager.setPasscode(id: vault.id, new: "1234")
        if case .failure(let error) = setRes {
            XCTFail("Failed to set passcode: \(error)")
        }
        
        // Verify get by passcode
        let fetchedVault = await manager.getVault(passcode: "1234")
        XCTAssertEqual(fetchedVault?.id, vault.id)
        
        // Change passcode
        let changeRes = await manager.changePasscode(old: "1234", new: "5678")
        if case .failure(let error) = changeRes {
            XCTFail("Failed to change passcode: \(error)")
        }
        
        // Verify old passcode doesn't work
        let oldVault = await manager.getVault(passcode: "1234")
        XCTAssertNil(oldVault)
        
        // Verify new passcode works
        let newVault = await manager.getVault(passcode: "5678")
        XCTAssertEqual(newVault?.id, vault.id)
        
        // Remove passcode
        _ = try await manager.removePasscode(id: vault.id)
        let removedVault = await manager.getVault(passcode: "5678")
        XCTAssertNil(removedVault)
        
        // Cleanup
        _ = await manager.deleteVault(vault)
    }
    
    func testDeleteVault() async throws {
        let vault = try await manager.addVault()
        let id = vault.id
        
        let result = await manager.deleteVault(vault)
        
        switch result {
        case .success:
            // Check folder deleted
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let folderURL = documentsDirectory.appendingPathComponent(id.uuidString)
            XCTAssertFalse(FileManager.default.fileExists(atPath: folderURL.path))
        case .failure(let error):
            XCTFail("Deletion failed: \(error)")
        }
    }
}
