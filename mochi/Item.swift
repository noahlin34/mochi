//
//  Item.swift
//  mochi
//
//  Created by Noah Lin  on 2026-02-01.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
