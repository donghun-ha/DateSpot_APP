import Foundation

class LoginService {
    /*
     사용자 데이터 백엔드 전송
     - Parameters:
        - email : 사용자 이메일
        - name : 사용자 이름
     */
    
    // 서버에 이메일, 이름 전송 후 JSON 응답
    func sendUserData(email: String, name: String) async throws -> [String: Any] {
        // FastAPI 주소 설정
        guard let url = URL(string: "https://fastapi.fre.today/login") else {
            print("❌ URL 생성 실패")
            throw URLError(.badURL)
        }
        
        print("🌐 URL: \(url)")
        
        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON 바디 구성
        let requestBody: [String: Any] = ["email": email, "name": name]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            print("📦 HTTP Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "No Body")")
        } catch {
            print("❌ JSON 직렬화 실패: \(error.localizedDescription)")
            throw error
        }
        
        // 비동기 네트워크 통신
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 응답 상태 확인
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 서버 응답 상태 코드: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    print("❌ 서버 응답 오류: \(httpResponse)")
                    throw URLError(.badServerResponse)
                }
            }
            
            // JSON 파싱
            do {
                guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("❌ 응답 데이터 파싱 실패")
                    throw URLError(.cannotParseResponse)
                }
                print("✅ 서버 응답 데이터: \(jsonResponse)")
                return jsonResponse
            } catch {
                print("❌ JSON 파싱 실패: \(error.localizedDescription)")
                throw error
            }
        } catch {
            print("❌ 네트워크 요청 실패: \(error.localizedDescription)")
            throw error
        }
    }
}
