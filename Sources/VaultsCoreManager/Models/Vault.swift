//
//  Vault.swift
//  VaultsCoreManager
//
//  Created by Majd Aldeyn Ez Alrejal on 12/1/25.
//

import Foundation

public struct Vault: Codable, Identifiable, Sendable {
    public let id: UUID
    public let creationDate: Date
    public var phoneNumber: String?
    public var passcode: String?
    public var ableToOpenViaBiometric: Bool = false
    
    public init(id: UUID = UUID(), creationDate: Date = Date(), phoneNumber: String? = nil, passcode: String? = nil) {
        self.id = id
        self.creationDate = creationDate
        self.phoneNumber = phoneNumber
        self.passcode = passcode
    }
}
