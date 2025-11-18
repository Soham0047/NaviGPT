import Foundation
import AVFoundation
import SwiftUI
import UIKit

// Simple configuration helper
private class SimpleConfig {
    static func getAPIKey() -> String? {
        // Try .env file first
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let content = try? String(contentsOfFile: envPath) {
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.hasPrefix("OPENAI_API_KEY=") {
                    let components = trimmed.components(separatedBy: "=")
                    if components.count >= 2 {
                        return components[1...].joined(separator: "=").trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        // Try Config.plist
        if let plistPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plistData = NSDictionary(contentsOfFile: plistPath) as? [String: String],
           let key = plistData["OPENAI_API_KEY"] {
            return key
        }
        
        // Try environment variable
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return envKey
        }
        
        return nil
    }
}

class LLmManager {
    private let apiKey: String
    let speechVoice = AVSpeechSynthesizer()
    
    init() {
        // Try to get API key from configuration
        if let key = SimpleConfig.getAPIKey() {
            self.apiKey = key
        } else {
            // Fallback to placeholder - this will cause API calls to fail gracefully
            self.apiKey = "your_openai_api_key_here"
            print("Warning: OpenAI API key not found. Please set OPENAI_API_KEY in your .env file or configuration.")
        }
    }
    
    func imageGuide(base64Image: String, location: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let location = location.filter { !$0.isNumber }
        let imageUrl = "data:image/jpeg;base64,\(base64Image)"
        
        let payload: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": "Based on the photo, tell the user if they are any physical obstructions like cars, red light, etc. Using the road: \(location), help direct the user safely. Let the user know if it is safe to walk. If the image provided is not clear, tell the user but don't describe the photo with more than 1 sentence. Only respond in 1 or 2 sentences."
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "image_url", "image_url": imageUrl]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                self.errorMessage()
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                completion(nil)
                return
            }
            
            do {
                let responseString = String(data: data, encoding: .utf8)
                print("Response Data: \(responseString ?? "No readable response data")")
                
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = responseDict["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error: Failed to parse JSON")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func mapGuide(base64Image: String, location: String, destination: String, stepInstruction: String, secondStepInstruction: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let location = location.filter { !$0.isNumber }
        let imageUrl = "data:image/jpeg;base64,\(base64Image)"
        
        let payload: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": "Based on the photo, tell the user if they are any physical obstructions like cars, red light, etc. Using the road: \(location), the instructions: \(stepInstruction) and then \(secondStepInstruction), and the user's destination: \(destination), help direct the user safely. Let the user know if it is safe to walk. If the image provided is not clear, tell the user but don't describe the photo with more than 1 sentence. Only respond in 2 or 3 sentences."
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "image_url", "image_url": imageUrl]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                self.errorMessage()
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                completion(nil)
                return
            }
            
            do {
                let responseString = String(data: data, encoding: .utf8)
                print("Response Data: \(responseString ?? "No readable response data")")
                
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = responseDict["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error: Failed to parse JSON")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func errorMessage() {
        let utterance = AVSpeechUtterance(string: "There seems to be a problem with your connection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.speechVoice.speak(utterance)
        }
    }
}
