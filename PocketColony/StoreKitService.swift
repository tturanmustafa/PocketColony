//
//  StoreKitService.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// StoreKitService.swift
// StoreKit 2 ile In-App Purchase yönetimi

import Foundation
import StoreKit
import Observation

@Observable
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()
    
    // Ürün ID'leri
    enum ProductID: String, CaseIterable {
        case gemsSmall = "com.yourcompany.pocketcolony.gems.small"
        case gemsMedium = "com.yourcompany.pocketcolony.gems.medium"
        case gemsLarge = "com.yourcompany.pocketcolony.gems.large"
        case battlePass = "com.yourcompany.pocketcolony.battlepass"
        case vipMonthly = "com.yourcompany.pocketcolony.vip"
        
        var gemAmount: Int {
            switch self {
            case .gemsSmall: return 100
            case .gemsMedium: return 600
            case .gemsLarge: return 1500
            case .battlePass: return 0
            case .vipMonthly: return 0
            }
        }
    }
    
    // Durum
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isVIP: Bool = false
    var hasBattlePass: Bool = false
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        transactionListener = listenForTransactions()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Ürünleri Yükle
    func loadProducts() async {
        do {
            let ids = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: Set(ids))
            products.sort { $0.price < $1.price }
            
            // Mevcut satın almaları kontrol et
            await updatePurchasedProducts()
            
            print("✅ StoreKit: \(products.count) ürün yüklendi")
        } catch {
            print("❌ StoreKit ürün yükleme hatası: \(error)")
        }
    }
    
    // MARK: - Satın Alma
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Ürüne göre işlem yap
            await handlePurchase(productID: transaction.productID)
            
            // Transaction'ı tamamla
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Satın Alma İşlemi
    private func handlePurchase(productID: String) async {
        guard let pid = ProductID(rawValue: productID) else { return }
        
        switch pid {
        case .gemsSmall, .gemsMedium, .gemsLarge:
            let gems = pid.gemAmount
            await MainActor.run {
                GameManager.shared.gameState.addResource(.gems, amount: Double(gems))
                GameManager.shared.showToast("💠 \(gems) Gem hesabına eklendi!", type: .success)
            }
            
        case .battlePass:
            await MainActor.run {
                GameManager.shared.gameState.battlePassPurchased = true
                hasBattlePass = true
                GameManager.shared.showToast("🎖️ Premium Sezon Bileti aktif!", type: .legendary)
            }
            
        case .vipMonthly:
            await MainActor.run {
                isVIP = true
                GameManager.shared.showToast("👑 VIP üyelik başladı!", type: .legendary)
            }
        }
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.handlePurchase(productID: transaction.productID)
                    await transaction.finish()
                } catch {
                    print("❌ Transaction doğrulama hatası: \(error)")
                }
            }
        }
    }
    
    // MARK: - Satın Almaları Güncelle
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
                
                if transaction.productID == ProductID.vipMonthly.rawValue {
                    isVIP = true
                }
                if transaction.productID == ProductID.battlePass.rawValue {
                    hasBattlePass = true
                }
            }
        }
    }
    
    // MARK: - Geri Yükleme
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            await MainActor.run {
                GameManager.shared.showToast("✅ Satın almalar geri yüklendi!", type: .success)
            }
        } catch {
            await MainActor.run {
                GameManager.shared.showToast("❌ Geri yükleme başarısız", type: .error)
            }
        }
    }
    
    // MARK: - Doğrulama
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Yardımcılar
    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }
    
    func formattedPrice(for id: ProductID) -> String {
        product(for: id)?.displayPrice ?? "—"
    }
}