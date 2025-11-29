import Foundation

public struct SDKConfiguration {
    
    // MARK: - API Configuration
    public struct API {
        public static let clientId = "A9x2KdLzQ1"
        public static let clientSecret = "mF7pYzAqN3x2LUcT5WQkjHgXiv0oD9"
        // public static let baseUrl = "http://10.6.226.57:7263/v1/api/"
        public static let baseUrl = "https://mobilecob-dev.bankbjb.co.id:8080/v1/api/"
        public static let kycResultUrl = "https://mobilecob-dev.bankbjb.co.id:8080/kyc-result"
        public static let successUrl = "https://mobilecob-dev.bankbjb.co.id:8080/success"
    }
    
    // MARK: - Environment Configuration
    public enum Environment {
        case staging
        case production
        
        public var baseUrl: String {
            switch self {
            case .staging:
                return "https://onekyc.ky.id.staging.gopayapi.com"
            case .production:
                return "https://onekyc.ky.id.gopayapi.com"
            }
        }
    }
    
    // MARK: - Current Environment
    public static let currentEnvironment: Environment = .staging
    
    // MARK: - Helper Methods
    public static func getClientId() -> String {
        return API.clientId
    }
    
    public static func getClientSecret() -> String {
        return API.clientSecret
    }
    
    public static func getBaseUrl() -> String {
        return currentEnvironment.baseUrl
    }
    
    public static func getKYCBaseUrl() -> String {
        return currentEnvironment.baseUrl
    }
    
    public static func getKYCResultUrl() -> String {
        return API.kycResultUrl
    }
    
    public static func getSuccessUrl() -> String {
        return API.successUrl
    }
}
