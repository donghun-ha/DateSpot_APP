//
//  NearFromDetails.swift
//  DateSpot
//
//  Created by mac on 12/28/24.
//

import SwiftUI

struct NearFromDetails: View {
    var nearbyPlaces: [PlaceData] // 근처 명소 리스트
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 상단 텍스트 섹션
                VStack(alignment: .leading, spacing: 8) {
                    Text("근처의 명소")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    Text("해당 장소와 가까운 명소들을 확인하세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                }
                
                // 장소 리스트
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(nearbyPlaces, id: \.name) { place in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(place.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Button(action: {
                                    print("Bookmarked \(place.name)")
                                }) {
                                    Image(systemName: "bookmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            HStack {
                                Text(place.address)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                
                                Spacer()
                                Text("\(String(format: "%.2fkm", calculateDistance(lat: place.lat, lng: place.lng)))")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            
                            // 이미지 (샘플)
                            ZStack {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 180)
                                    .cornerRadius(12)
                                
                                Text("이미지 로드 예정")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Nearby Places")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 거리 계산 함수
    private func calculateDistance(lat: Double, lng: Double) -> Double {
        // 현재 위치(예: 서울시청 좌표)
        let currentLat = 37.5665
        let currentLng = 126.9780
        
        // 위도 및 경도의 차
        let deltaLat = lat - currentLat
        let deltaLng = lng - currentLng
        
        // 단순 거리 계산 (유클리드 거리)
        return sqrt(deltaLat * deltaLat + deltaLng * deltaLng) * 111 // 대략적인 거리(km)
    }
}
