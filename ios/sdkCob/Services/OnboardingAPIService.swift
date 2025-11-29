import Foundation

public class OnboardingAPIService {
    
    public static let shared = OnboardingAPIService()
    
    private init() {}
    
    public func startOnboarding(phoneNumber: String, email: String, completion: @escaping (Result<StartOnboardingResponse, Error>) -> Void) {
        
        // Use baseUrl from Configuration
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/start"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            print("❌ Invalid URL: \(fullUrl)")
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add x-client-platform header if available
        if let clientPlatform = CobSDKManager.shared.clientPlatform {
            request.setValue(clientPlatform, forHTTPHeaderField: "x-client-platform")
            print("  - x-client-platform: \(clientPlatform)")
        }
        
        let requestBody = StartOnboardingRequest(phoneNumber: phoneNumber, email: email)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            // Log Request
            print("🚀 API REQUEST:")
            print("URL: \(fullUrl)")
            print("Method: POST")
            print("Headers:")
            print("  - accept: application/json")
            print("  - x-client-id: \(SDKConfiguration.getClientId())")
            print("  - x-client-secret: \(SDKConfiguration.getClientSecret())")
            print("  - Content-Type: application/json")
            print("Body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
            print("---")
            
        } catch {
            print("❌ Failed to encode request body: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Log Response
            print("📥 API RESPONSE:")
            
            if let error = error {
                print("❌ Network Error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(.failure(APIError.noData))
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            print("---")
            
            do {
                let response = try JSONDecoder().decode(StartOnboardingResponse.self, from: data)
                print("✅ Successfully parsed response: \(response)")
                
                // Save session data
                if let sessionId = response.data?.sessionId,
                   let identityId = response.data?.identityId {
                    SessionManager.shared.setSessionData(sessionId: sessionId, identityId: identityId)
                }
                
                // Save accountType and cardType
                if let accountType = response.data?.accountType {
                    SessionManager.shared.setIdAccountType(accountType)
                }
                if let cardType = response.data?.cardType {
                    SessionManager.shared.setIdCardType(cardType)
                }
                
                // Save checkpoint
                if let checkpoint = response.data?.checkpoint {
                    SessionManager.shared.setCheckpoint(checkpoint)
                }
                
                completion(.success(response))
            } catch {
                print("❌ Failed to decode response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func validateOTP(otp: String, completion: @escaping (Result<ValidateOTPResponse, Error>) -> Void) {
        
        guard let identityId = SessionManager.shared.getIdentityId() else {
            print("❌ No identity ID found in session")
            completion(.failure(APIError.noIdentityId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "one-time-password/validate"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            print("❌ Invalid URL: \(fullUrl)")
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(identityId, forHTTPHeaderField: "x-user-id")
        request.setValue("SDK", forHTTPHeaderField: "x-source")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ValidateOTPRequest(otp: otp)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            // Log Request
            print("🚀 OTP VALIDATION REQUEST:")
            print("URL: \(fullUrl)")
            print("Method: POST")
            print("Headers:")
            print("  - accept: application/json")
            print("  - x-client-id: \(SDKConfiguration.getClientId())")
            print("  - x-client-secret: \(SDKConfiguration.getClientSecret())")
            print("  - x-user-id: \(identityId)")
            print("  - x-source: SDK")
            print("  - Content-Type: application/json")
            print("Body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
            print("---")
            
        } catch {
            print("❌ Failed to encode OTP request body: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // Log Response
            print("📥 OTP VALIDATION RESPONSE:")
            
            if let error = error {
                print("❌ Network Error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(.failure(APIError.noData))
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            print("---")
            
            do {
                let response = try JSONDecoder().decode(ValidateOTPResponse.self, from: data)
                print("✅ Successfully parsed OTP validation response: \(response)")
                completion(.success(response))
            } catch {
                print("❌ Failed to decode OTP validation response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func getAccountTypes(page: Int = 1, length: Int = 10, completion: @escaping (Result<AccountTypeResponse, Error>) -> Void) {
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "account-type/get"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = AccountTypeRequest(page: page, length: length)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("🚀 ACCOUNT TYPE REQUEST: \(fullUrl)")
            print("Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            print("📥 ACCOUNT TYPE RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                let response = try JSONDecoder().decode(AccountTypeResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func getCardTypes(page: Int = 1, length: Int = 10, completion: @escaping (Result<CardTypeResponse, Error>) -> Void) {
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "card-type/get"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = CardTypeRequest(page: page, length: length)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("🚀 CARD TYPE REQUEST: \(fullUrl)")
            print("Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            print("📥 CARD TYPE RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                let response = try JSONDecoder().decode(CardTypeResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func getTermsAndCondition(completion: @escaping (Result<TermsAndConditionResponse, Error>) -> Void) {
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "term-and-condition"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        
        print("🚀 TERMS AND CONDITION REQUEST: \(fullUrl)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            // print("📥 TERMS AND CONDITION RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                let response = try JSONDecoder().decode(TermsAndConditionResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func initiateOnboarding(completion: @escaping (Result<InitiateOnboardingResponse, Error>) -> Void) {
        
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found")
            completion(.failure(APIError.noSessionId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/initiate"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(sessionId, forHTTPHeaderField: "x-session-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use saved account type and card type, or fallback to defaults
        let accountType = SessionManager.shared.getIdAccountType() ?? "EA"
        let cardType = SessionManager.shared.getIdCardType() ?? "Gold"
        let requestBody = InitiateOnboardingRequest(accountType: accountType, cardType: cardType)
        
        print("📋 Using AccountType: \(accountType), CardType: \(cardType)")
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("🚀 INITIATE ONBOARDING REQUEST: \(fullUrl)")
            print("📤 Headers:")
            print("   accept: application/json")
            print("   x-client-id: \(SDKConfiguration.getClientId())")
            print("   x-client-secret: \(SDKConfiguration.getClientSecret())")
            print("   x-session-id: \(sessionId)")
            print("   Content-Type: application/json")
            print("📤 Body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            print("📥 INITIATE ONBOARDING RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                let response = try JSONDecoder().decode(InitiateOnboardingResponse.self, from: data)
                
//                 Save token to session - API response token (commented out)
                 if let token = response.data?.token {
                     SessionManager.shared.setToken(token)
                 }
                
                // Use hardcoded token instead
//                let hardcodedToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
//                SessionManager.shared.setToken(hardcodedToken)
                
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func reinitiateOnboarding(completion: @escaping (Result<ReinitiateOnboardingResponse, Error>) -> Void) {
        
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found")
            completion(.failure(APIError.noSessionId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/reinitiate"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(sessionId, forHTTPHeaderField: "x-session-id")

        // Add x-client-platform header if available
        if let clientPlatform = CobSDKManager.shared.clientPlatform {
            request.setValue(clientPlatform, forHTTPHeaderField: "x-client-platform")
        }
        
        print("🚀 REINITIATE ONBOARDING REQUEST: \(fullUrl)")
        print("Headers: x-session-id: \(sessionId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            print("📥 REINITIATE ONBOARDING RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                let response = try JSONDecoder().decode(ReinitiateOnboardingResponse.self, from: data)
                
                if let token = response.data?.token {
                    SessionManager.shared.setToken(token)
                }
                
                // Update sessionId with new one from reinitiate
                if let newSessionId = response.data?.sessionId {
                    if let currentIdentityId = SessionManager.shared.getIdentityId() {
                        SessionManager.shared.setSessionData(sessionId: newSessionId, identityId: currentIdentityId)
                    }
                }
                
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func checkSubmission(completion: @escaping (Result<CheckSubmissionResponse, Error>) -> Void) {
        
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found")
            completion(.failure(APIError.noSessionId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/check-submission"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(sessionId, forHTTPHeaderField: "x-session-id")
        
        print("🚀 CHECK SUBMISSION REQUEST: \(fullUrl)")
        print("Headers: x-session-id: \(sessionId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            print("📥 CHECK SUBMISSION RESPONSE: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                let response = try JSONDecoder().decode(CheckSubmissionResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    public func updateCheckpoint(checkpoint: String, completion: @escaping (Result<UpdateCheckpointResponse, Error>) -> Void) {
    
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found")
            completion(.failure(APIError.noSessionId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/update-checkpoint"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            print("❌ Invalid URL: \(fullUrl)")
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(sessionId, forHTTPHeaderField: "x-session-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = UpdateCheckpointRequest(checkpoint: checkpoint)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("🚀 UPDATE CHECKPOINT REQUEST:")
            print("URL: \(fullUrl)")
            print("Method: PUT")
            print("Headers:")
            print("  - accept: application/json")
            print("  - x-client-id: \(SDKConfiguration.getClientId())")
            print("  - x-client-secret: \(SDKConfiguration.getClientSecret())")
            print("  - x-session-id: \(sessionId)")
            print("  - Content-Type: application/json")
            print("Body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
            print("---")
            
        } catch {
            print("❌ Failed to encode update checkpoint request body: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            print("📥 UPDATE CHECKPOINT RESPONSE:")
            
            if let error = error {
                print("❌ Network Error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(.failure(APIError.noData))
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            print("---")
            
            do {
                let response = try JSONDecoder().decode(UpdateCheckpointResponse.self, from: data)
                print("✅ Successfully parsed update checkpoint response: \(response)")
                completion(.success(response))
            } catch {
                print("❌ Failed to decode update checkpoint response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func sendFCMDeviceToken(_ token: String, completion: @escaping (Result<FCMDeviceTokenResponse, Error>) -> Void) {
        
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found")
            completion(.failure(APIError.noSessionId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/device-token"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            print("❌ Invalid URL: \(fullUrl)")
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(sessionId, forHTTPHeaderField: "x-session-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = FCMDeviceTokenRequest(deviceToken: token)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("🚀 FCM DEVICE TOKEN REQUEST:")
            print("URL: \(fullUrl)")
            print("Method: POST")
            print("Headers:")
            print("  - accept: application/json")
            print("  - x-client-id: \(SDKConfiguration.getClientId())")
            print("  - x-client-secret: \(SDKConfiguration.getClientSecret())")
            print("  - x-session-id: \(sessionId)")
            print("  - Content-Type: application/json")
            print("Body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
            print("---")
            
        } catch {
            print("❌ Failed to encode FCM device token request body: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            print("📥 FCM DEVICE TOKEN RESPONSE:")
            
            if let error = error {
                print("❌ Network Error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
                print("Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(.failure(APIError.noData))
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            print("---")
            
            do {
                let response = try JSONDecoder().decode(FCMDeviceTokenResponse.self, from: data)
                print("✅ Successfully sent FCM device token")
                completion(.success(response))
            } catch {
                print("❌ Failed to decode FCM device token response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    public func longPooling(completion: @escaping (Result<LongPoolingResponse, Error>) -> Void) {
        
        guard let sessionId = SessionManager.shared.getSessionId() else {
            print("❌ No session ID found")
            completion(.failure(APIError.noSessionId))
            return
        }
        
        let baseUrl = SDKConfiguration.API.baseUrl
        let endpoint = "onboarding/long-pooling"
        let fullUrl = baseUrl + endpoint
        
        guard let url = URL(string: fullUrl) else {
            print("❌ Invalid URL: \(fullUrl)")
            completion(.failure(APIError.invalidResponse))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(SDKConfiguration.getClientId(), forHTTPHeaderField: "x-client-id")
        request.setValue(SDKConfiguration.getClientSecret(), forHTTPHeaderField: "x-client-secret")
        request.setValue(sessionId, forHTTPHeaderField: "x-session-id")
        
        print("🚀 LONG POOLING REQUEST: \(fullUrl)")
        print("Headers: x-session-id: \(sessionId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            print("📥 LONG POOLING RESPONSE:")
            
            if let error = error {
                print("❌ Network Error: \(error)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No response data")
                completion(.failure(APIError.noData))
                return
            }
            
            print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            print("---")
            
            do {
                let response = try JSONDecoder().decode(LongPoolingResponse.self, from: data)
                print("✅ Successfully parsed long pooling response")
                completion(.success(response))
            } catch {
                print("❌ Failed to decode long pooling response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Request/Response Models
public struct StartOnboardingRequest: Codable {
    let phoneNumber: String
    let email: String
}

public struct StartOnboardingResponse: Codable {
    let succeeded: Bool?
    let message: String?
    let data: OnboardingData?
    let statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case succeeded
        case message
        case data
        case statusCode
    }
}

public struct OnboardingData: Codable {
    let sessionId: String?
    let status: String?
    let otpExpiresAt: String?
    let identityId: String?
    let checkpoint: String?
    let accountType: String?
    let cardType: String?
}

// MARK: - OTP Validation Models
public struct ValidateOTPRequest: Codable {
    let otp: String
}

public struct ValidateOTPResponse: Codable {
    let success: Bool?
    let message: String?
    let data: OTPValidationData?
    let succeeded: Bool?
}

public struct OTPValidationData: Codable {
    let isValid: Bool?
    let status: String?
}

public enum APIError: Error {
    case noData
    case invalidResponse
    case noIdentityId
    case noSessionId
}

// MARK: - Account Type Models
public struct AccountTypeRequest: Codable {
    let page: Int
    let length: Int
}

public struct AccountTypeResponse: Codable {
    let pageNumber: Int?
    let pageSize: Int?
    let info: PageInfo?
    let succeeded: Bool?
    let data: [AccountType]?
    let statusCode: Int?
}

public struct PageInfo: Codable {
    let totalPage: Int?
    let currentPage: Int?
    let length: Int?
}

public struct AccountType: Codable {
    let id: String?
    let name: String?
    let description: String?
    let imageUrl: String?
}

// MARK: - Card Type Models
public struct CardTypeRequest: Codable {
    let page: Int
    let length: Int
}

public struct CardTypeResponse: Codable {
    let pageNumber: Int?
    let pageSize: Int?
    let info: PageInfo?
    let succeeded: Bool?
    let data: [CardType]?
    let statusCode: Int?
}

public struct CardType: Codable {
    let id: String?
    let name: String?
    let description: String?
    let imageUrl: String?
}

// MARK: - Terms and Condition Models
public struct TermsAndConditionResponse: Codable {
    let succeeded: Bool?
    let data: TermsAndConditionData?
    let statusCode: Int?
}

public struct TermsAndConditionData: Codable {
    let contentId: String?
}

// MARK: - Initiate Onboarding Models
public struct InitiateOnboardingRequest: Codable {
    let accountType: String
    let cardType: String
}

public struct InitiateOnboardingResponse: Codable {
    let succeeded: Bool?
    let data: InitiateOnboardingData?
    let statusCode: Int?
}

public struct InitiateOnboardingData: Codable {
    let token: String?
}

// MARK: - Reinitiate Onboarding Models
public struct ReinitiateOnboardingResponse: Codable {
    let succeeded: Bool?
    let data: ReinitiateOnboardingData?
    let statusCode: Int?
    let message: String?
}

public struct ReinitiateOnboardingData: Codable {
    let token: String?
    let sessionId: String?
}

// MARK: - Check Submission Models
public struct CheckSubmissionResponse: Codable {
    let succeeded: Bool?
    let data: CheckSubmissionData?
    let statusCode: Int?
}

public struct CheckSubmissionData: Codable {
    let status: String?
    let webviewUrl: String?
    let verificationResult: VerificationResult?
}

public struct VerificationResult: Codable {
    let nik: String?
    let name: String?
    let dateOfBirth: String?
    let selfie: String?
}

public struct UpdateCheckpointRequest: Codable {
    let checkpoint: String
}

public struct UpdateCheckpointResponse: Codable {
    let succeeded: Bool?
    let message: String?
    let data: UpdateCheckpointData?
    let statusCode: Int?
}

public struct UpdateCheckpointData: Codable {
    let checkpoint: String?
}

// MARK: - FCM Device Token Models
public struct FCMDeviceTokenRequest: Codable {
    let deviceToken: String
}

public struct FCMDeviceTokenResponse: Codable {
    let succeeded: Bool?
    let message: String?
    let statusCode: Int?
}

// MARK: - Long Pooling Models
public struct LongPoolingResponse: Codable {
    let jobId: String?
    let userId: String?
    let title: String?
    let body: String?
    let data: LongPoolingData?
}

public struct LongPoolingData: Codable {
    let sessionId: String?
    let userId: String?
    let submissionId: String?
    let status: String?
    let type: String?
}
