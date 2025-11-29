import Foundation

public class SessionManager {
    
    public static let shared = SessionManager()
    
    private init() {}
    
    // MARK: - Session Data
    private var sessionId: String?
    private var identityId: String?
    private var idAccountType: String?
    private var idCardType: String?
    private var token: String?
    private var checkpoint: String?
    
    // MARK: - Public Methods
    public func setSessionData(sessionId: String?, identityId: String?) {
        self.sessionId = sessionId
        self.identityId = identityId
        print("📝 Session data saved - SessionID: \(sessionId ?? "nil"), IdentityID: \(identityId ?? "nil")")
    }
    
    public func getSessionId() -> String? {
        return sessionId
    }
    
    public func getIdentityId() -> String? {
        return identityId
    }
    
    public func setIdAccountType(_ idAccountType: String?) {
        self.idAccountType = idAccountType
        print("📝 Account Type ID saved: \(idAccountType ?? "nil")")
    }
    
    public func getIdAccountType() -> String? {
        return idAccountType
    }
    
    public func setIdCardType(_ idCardType: String?) {
        self.idCardType = idCardType
        print("📝 Card Type ID saved: \(idCardType ?? "nil")")
    }
    
    public func getIdCardType() -> String? {
        return idCardType
    }
    
    public func setToken(_ token: String?) {
        self.token = token
        print("📝 Token saved: \(token?.prefix(20) ?? "nil")...")
    }
    
    public func getToken() -> String? {
        return token
    }
    
    public func setCheckpoint(_ checkpoint: String?) {
        self.checkpoint = checkpoint
        print("📝 Checkpoint saved: \(checkpoint ?? "nil")")
    }
    
    public func getCheckpoint() -> String? {
        return checkpoint
    }
    
    public func clearSession() {
        sessionId = nil
        identityId = nil
        idAccountType = nil
        idCardType = nil
        token = nil
        checkpoint = nil
        print("🗑️ Session data cleared")
    }
    
    public func hasValidSession() -> Bool {
        return sessionId != nil && identityId != nil
    }
}
