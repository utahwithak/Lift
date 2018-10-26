//
//  StoreTableCell.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa
import StoreKit

class StoreTableCell: NSTableCellView {

    @IBAction func purchaseProduct(_ sender: NSButton) {
        guard let product = objectValue as? SKProduct else {
            return
        }
        IAPHelper.shared.purchase(product: product)
    }
}
