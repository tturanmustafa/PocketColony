//
//  CloudKitService.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// CloudKitService.swift
// iCloud CloudKit backend servisi

import Foundation
import CloudKit

class CloudKitService {
    static let shared = CloudKitService()
    
    private let container = CKContainer(identifier: "iCloud.com.yourcompany.pocketcolony")
    private var privateDB: CKDatabase { container.privateCloudDatabase }
    private var publicDB: CKDatabase { container.publicCloudDatabase }
    
    private init() {}
    
    // MARK: - Oyun Kaydetme (Private DB)
    func saveGameState(_ state: GameState) async {
        do {
            let data = try JSONEncoder().encode(state)
            
            // Mevcut kaydı güncelle veya yeni oluştur
            let recordID = CKRecord.ID(recordName: "currentSave")
            let record: CKRecord
            
            do {
                record = try await privateDB.record(for: recordID)
            } catch {
                record = CKRecord(recordType: "ColonyData", recordID: recordID)
            }
            
            record["jsonData"] = data as CKRecordValue
            record["version"] = state.version as CKRecordValue
            record["depth"] = state.depth as CKRecordValue
            record["wave"] = state.wave as CKRecordValue
            record["lastSave"] = Date() as CKRecordValue
            
            try await privateDB.save(record)
            print("✅ CloudKit: Oyun kaydedildi")
        } catch {
            print("❌ CloudKit kaydetme hatası: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Oyun Yükleme (Private DB)
    func loadGameState() async -> GameState? {
        do {
            let recordID = CKRecord.ID(recordName: "currentSave")
            let record = try await privateDB.record(for: recordID)
            
            guard let data = record["jsonData"] as? Data else { return nil }
            let state = try JSONDecoder().decode(GameState.self, from: data)
            print("✅ CloudKit: Oyun yüklendi")
            return state
        } catch {
            print("ℹ️ CloudKit: Kayıtlı oyun yok veya hata: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Sıralama Tablosu (Public DB)
    func submitLeaderboardScore(playerName: String, depth: Int, wave: Int, colonists: Int) async {
        do {
            let record = CKRecord(recordType: "LeaderboardEntry")
            record["playerName"] = playerName as CKRecordValue
            record["depth"] = depth as CKRecordValue
            record["wave"] = wave as CKRecordValue
            record["colonists"] = colonists as CKRecordValue
            record["score"] = (depth * 100 + wave * 50 + colonists * 10) as CKRecordValue
            record["submittedAt"] = Date() as CKRecordValue
            
            try await publicDB.save(record)
            print("✅ CloudKit: Skor gönderildi")
        } catch {
            print("❌ CloudKit skor hatası: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sıralama Listesini Çek
    func fetchLeaderboard(limit: Int = 50) async -> [(name: String, score: Int, depth: Int)] {
        let query = CKQuery(recordType: "LeaderboardEntry", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "score", ascending: false)]
        
        do {
            let results = try await publicDB.records(matching: query, resultsLimit: limit)
            
            return results.matchResults.compactMap { _, result in
                guard let record = try? result.get(),
                      let name = record["playerName"] as? String,
                      let score = record["score"] as? Int,
                      let depth = record["depth"] as? Int else { return nil }
                return (name, score, depth)
            }
        } catch {
            print("❌ CloudKit sıralama hatası: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Sezon Konfigürasyonu (Public DB - Admin tarafından)
    func fetchSeasonConfig() async -> (seasonID: Int, endDate: Date)? {
        let query = CKQuery(recordType: "SeasonConfig", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "seasonID", ascending: false)]
        
        do {
            let results = try await publicDB.records(matching: query, resultsLimit: 1)
            guard let (_, result) = results.matchResults.first,
                  let record = try? result.get(),
                  let seasonID = record["seasonID"] as? Int,
                  let endDate = record["endDate"] as? Date else { return nil }
            return (seasonID, endDate)
        } catch {
            return nil
        }
    }
    
    // MARK: - CloudKit Subscription (Push Notifications)
    func setupSubscriptions() async {
        let subscriptionID = "season-changes"
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: "SeasonConfig",
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let info = CKSubscription.NotificationInfo()
        info.titleLocalizationKey = "Yeni Sezon!"
        info.alertLocalizationKey = "Yeni bir sezon başladı. Hemen giriş yap!"
        info.shouldBadge = true
        info.soundName = "default"
        subscription.notificationInfo = info
        
        do {
            try await publicDB.save(subscription)
            print("✅ CloudKit: Subscription kuruldu")
        } catch {
            print("❌ CloudKit subscription hatası: \(error.localizedDescription)")
        }
    }
}