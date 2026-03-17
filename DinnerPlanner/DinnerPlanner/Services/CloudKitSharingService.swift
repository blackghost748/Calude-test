import Foundation
import CloudKit
import SwiftData
import UIKit

/// Manages CloudKit sharing (CKShare) for the family group.
/// The app uses NSPersistentCloudKitContainer which syncs SwiftData records automatically.
/// This service handles *sharing* – creating and accepting CKShare invitations.
@MainActor
final class CloudKitSharingService: ObservableObject {

    @Published var shareURL: URL?
    @Published var isSharingActive: Bool = false
    @Published var participantNames: [String] = []
    @Published var errorMessage: String?

    private let container = CKContainer(identifier: "iCloud.com.dinnerplanner.app")

    // MARK: - Create Share

    /// Creates or retrieves a CKShare for the given root record and returns a sharing URL.
    func createOrFetchShare(for rootRecordName: String) async {
        do {
            let recordID = CKRecord.ID(recordName: rootRecordName, zoneID: sharedZoneID())
            let record = CKRecord(recordType: "FamilyGroupRoot", recordID: recordID)

            let share = CKShare(rootRecord: record)
            share[CKShare.SystemFieldKey.title] = "Familienplanung" as CKRecordValue
            share.publicPermission = .readWrite

            let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
            operation.savePolicy = .ifServerRecordUnchanged

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success: continuation.resume()
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
                container.privateCloudDatabase.add(operation)
            }

            // Fetch the share URL
            if let url = share.url {
                shareURL = url
                isSharingActive = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Accept Share

    /// Called when the app is opened via a share URL (universal link / CKShare URL).
    func acceptShare(metadata: CKShare.Metadata) async {
        do {
            let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                operation.acceptSharesResultBlock = { result in
                    switch result {
                    case .success: continuation.resume()
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                }
                CKContainer(identifier: metadata.containerIdentifier).add(operation)
            }
            isSharingActive = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - QR Code Generation

    func generateQRCode(from urlString: String) -> UIImage? {
        guard let data = urlString.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scale = 10.0
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return UIImage(ciImage: scaled)
    }

    // MARK: - Participants

    func fetchParticipants(shareURL: URL) async {
        // Fetching participant details requires fetching the CKShare record.
        // Simplified: show iCloud record names.
        do {
            let shareRecordID = CKRecord.ID(recordName: "_\(shareURL.lastPathComponent)")
            let record = try await container.sharedCloudDatabase.record(for: shareRecordID)
            if let share = record as? CKShare {
                participantNames = share.participants.compactMap {
                    $0.userIdentity.nameComponents?.formatted(.name(style: .short))
                }
            }
        } catch {
            // Silently ignore – participants list is informational only
        }
    }

    // MARK: - Helpers

    private func sharedZoneID() -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: "DinnerPlannerSharedZone", ownerName: CKCurrentUserDefaultName)
    }
}
