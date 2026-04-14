import Foundation
import Supabase

/// Reads Supabase project URL and anon key from the app bundle (`Info.plist`).
enum SupabaseConfig {
    private static let urlKey = "SUPABASE_URL"
    private static let anonKeyKey = "SUPABASE_ANON_KEY"

    /// `true` when both URL and anon key are non-empty in `Info.plist`.
    static var isConfigured: Bool {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: urlKey) as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: anonKeyKey) as? String
        else {
            return false
        }
        return !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Builds a client, or returns `nil` if configuration is missing or invalid.
    ///
    /// `SupabaseClient` force-unwraps `supabaseURL.host` when building the auth storage key; URLs without a host crash.
    static func makeClient() -> SupabaseClient? {
        guard isConfigured,
              let urlString = Bundle.main.object(forInfoDictionaryKey: urlKey) as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: anonKeyKey) as? String
        else {
            return nil
        }
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmedURL),
              let host = url.host,
              !host.isEmpty,
              let scheme = url.scheme,
              scheme == "https" || scheme == "http"
        else {
            return nil
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: trimmedKey,
            options: .init(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}

/// Maps a username to a stable email for Supabase email/password auth.
enum AuthEmailNormalizer {
    private static let syntheticDomain = "users.bibletodo.app"

    /// If `input` contains `@`, it is treated as a full email. Otherwise it becomes `normalized@users.bibletodo.app`.
    static func authEmail(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        if trimmed.contains("@") {
            return trimmed.lowercased()
        }
        let local = trimmed.lowercased().filter { $0.isLetter || $0.isNumber || "._-".contains($0) }
        return local.isEmpty ? "\(trimmed.lowercased())@\(syntheticDomain)" : "\(local)@\(syntheticDomain)"
    }
}
