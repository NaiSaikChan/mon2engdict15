//
//  DataLoader.swift
//  mon2engdict
//
//  Created by Saik Chan on 19/9/24.
//
//  Note: This file is no longer used. The app now uses SQLite via DatabaseManager.
//  Kept for the Notification.Name extension only.

import Foundation

/// Notification posted when dictionary data is ready (kept for backward compatibility).
extension Notification.Name {
    static let dictionaryDataDidLoad = Notification.Name("dictionaryDataDidLoad")
}
