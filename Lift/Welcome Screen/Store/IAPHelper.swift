//
//  IAPHelper.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
import StoreKit

class IAPHelper: NSObject {

    static let shared = IAPHelper()

    static let identifiers = Set(["support0", "support1", "support2", "support3", "support4", "continualSupport0", "continualSupport1"])
    let productRequest = SKProductsRequest(productIdentifiers: IAPHelper.identifiers)

    @objc dynamic var products = [SKProduct]()

    //Initialize the helper.
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    func load() {
        productRequest.delegate = self
        productRequest.start()
    }
    func purchase(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

}

extension IAPHelper: SKPaymentTransactionObserver {

    //Observe transaction updates.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {

    }

}

extension IAPHelper: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products.sorted(by: { $0.price.doubleValue > $1.price.doubleValue })
        }
    }
}

extension SKProduct {
    @objc dynamic var localizedPrice: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = priceLocale
        return numberFormatter.string(from: price) ?? ""
    }
}
