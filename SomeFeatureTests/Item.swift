//
//  Item.swift
//  SomeFeatureTests
//
//  Created by Arbab Nawaz on 6/5/24.
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
