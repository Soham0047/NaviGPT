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
        // Read API key from Config.plist or environment
        if let apiKey = ConfigManager.shared.getValue(forKey: "OpenAIAPIKey") as? String, !apiKey.isEmpty {
            self.apiKey = apiKey
            print("LLmManager initialized with API key from config")
        } else {
            self.apiKey = ""
            print("⚠️ Warning: OpenAI API key not found. Please add it to Config.plist")
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
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "Analyze the image for navigation assistance. If the user is indoors, describe the room, obstacles (chairs, tables), and locate doors or exits. If outdoors, identify cars, traffic lights, and sidewalks. Current location context: \(location). Provide clear, safe directions in 2 sentences."],
                        ["type": "image_url", "image_url": ["url": imageUrl]]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion("Network Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                completion("Error: No data received from server")
                return
            }
            
            do {
                let responseString = String(data: data, encoding: .utf8)
                print("Response Data: \(responseString ?? "No readable response data")")
                
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    
                    // Check for API Error
                    if let errorDict = responseDict["error"] as? [String: Any],
                       let errorMessage = errorDict["message"] as? String {
                        print("API Error: \(errorMessage)")
                        completion("OpenAI Error: \(errorMessage)")
                        return
                    }
                    
                    if let choices = responseDict["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(content)
                    } else {
                        completion("Error: Could not parse response content")
                    }
                } else {
                    completion("Error: Invalid JSON response")
                }
            } catch {
                print("Error: Failed to parse JSON: \(error.localizedDescription)")
                completion("Error: Failed to parse JSON response")
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
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "You are a navigation assistant. Sync the visual scene with the map instructions. \nMap Instruction: \(stepInstruction). \nNext: \(secondStepInstruction). \nDestination: \(destination). \nLocation: \(location). \n\nAnalyze the image: \n1. Confirm if the user is facing the correct direction based on the instruction (e.g., if instruction says 'turn right', is there a turn visible?). \n2. Identify immediate obstacles. \n3. If indoors, guide to the exit. \n4. Provide a single, clear directive combining visual and map data."],
                        ["type": "image_url", "image_url": ["url": imageUrl]]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network Error: \(error.localizedDescription)")
                completion("Network Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received")
                completion("Error: No data received from server")
                return
            }
            
            do {
                let responseString = String(data: data, encoding: .utf8)
                print("Response Data: \(responseString ?? "No readable response data")")
                
                if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    
                    // Check for API Error
                    if let errorDict = responseDict["error"] as? [String: Any],
                       let errorMessage = errorDict["message"] as? String {
                        print("API Error: \(errorMessage)")
                        completion("OpenAI Error: \(errorMessage)")
                        return
                    }
                    
                    if let choices = responseDict["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(content)
                    } else {
                        completion("Error: Could not parse response content")
                    }
                } else {
                    completion("Error: Invalid JSON response")
                }
            } catch {
                print("Error: Failed to parse JSON: \(error.localizedDescription)")
                completion("Error: Failed to parse JSON response")
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
