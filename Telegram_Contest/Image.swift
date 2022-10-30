//
//  Image.swift
//  Telegram_Contest
//
//  Created by Artem Shuneyko on 13.10.22.
//

import SwiftUI
import UIKit

struct Image: Identifiable {

    let id = UUID()
    let url: URL

}

extension Image: Equatable {
    static func ==(lhs: Image, rhs: Image) -> Bool {
        return lhs.id == rhs.id && lhs.id == rhs.id
    }
}
