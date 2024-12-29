import SwiftUI
import Foundation

@MainActor
class PlaceViewModel: ObservableObject {
    @Published private(set) var places: [PlaceData] = [] // 전체 장소 리스트
    @Published private(set) var images: [UIImage] = [] // 로드된 이미지 리스트
    private let baseURL = "https://fastapi.fre.today/place/" // 기본 API URL

    // Fetch Places
    func fetchPlaces() async {
        do {
            let fetchedPlaces = try await fetchPlacesFromAPI()
            self.places = fetchedPlaces
            print("✅ 데이터 다운로드 성공: \(self.places)")
        } catch {
            print("❌ 데이터 다운로드 실패: \(error.localizedDescription)")
        }
    }

    // Fetch Image Keys
    func fetchImageKeys(for name: String) async -> [String] {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "\(baseURL)images/?name=\(encodedName)") else {
            print("Invalid URL for fetchImageKeys")
            return []
        }
        
        do {
            print("Fetching image keys for name: \(name)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Image keys HTTP response status code: \(httpResponse.statusCode)")
            }

            let returnresponse = try JSONDecoder().decode([String: [String]].self, from: data)
            let keys = returnresponse["images"] ?? []
            print("Fetched image keys: \(keys)")
            return keys
        } catch {
            print("Failed to fetch image keys: \(error)")
            return []
        }
    }

    // Fetch Single Image
    func fetchImage(fileKey: String) async -> UIImage? {
        guard let url = URL(string: "\(baseURL)image/?file_key=\(fileKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fileKey)") else {
            print("Invalid URL for fetchImage")
            return nil
        }
        
        do {
            print("Fetching image for fileKey: \(fileKey)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Image HTTP response status code: \(httpResponse.statusCode)")
            }

            guard let image = UIImage(data: data) else {
                print("Failed to convert data to UIImage for fileKey: \(fileKey)")
                return nil
            }

            print("Successfully fetched image for fileKey: \(fileKey)")
            return image
        } catch {
            print("Failed to fetch image: \(error)")
            return nil
        }
    }

    // Load Images for Place
    func loadImages(for name: String) async {
        print("Loading images for place: \(name)")
        let imageKeys = await fetchImageKeys(for: name)

        guard !imageKeys.isEmpty else {
            print("No image keys found for place: \(name)")
            return
        }

        var loadedImages: [UIImage] = []

        for key in imageKeys {
            if let image = await fetchImage(fileKey: key) {
                loadedImages.append(image)
            } else {
                print("Failed to load image for key: \(key)")
            }
        }

        if loadedImages.isEmpty {
            print("No images loaded for place: \(name)")
        } else {
            print("Successfully loaded \(loadedImages.count) images for place: \(name)")
        }

        self.images = loadedImages
    }
}

extension PlaceViewModel {
    // Fetch Places from API
    private func fetchPlacesFromAPI() async throws -> [PlaceData] {
        guard let url = URL(string: "\(baseURL)select") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        // HTTP 상태 코드 확인
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // JSON 디코딩
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([PlaceData].self, from: data)
        } catch {
            print("❌ 데이터 파싱 실패: \(error)")
            throw error
        }
    }
}

