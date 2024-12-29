import Foundation

@MainActor
class PlaceViewModel: ObservableObject {
    @Published var places: [PlaceData] = [] // 전체 장소 리스트
    private let baseURL = "https://fastapi.fre.today/place/select" // 기본 API URL

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
}

extension PlaceViewModel {
    // Fetch Places from API
    private func fetchPlacesFromAPI() async throws -> [PlaceData] {
        guard let url = URL(string: baseURL) else {
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

