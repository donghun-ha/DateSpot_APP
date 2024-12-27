//
//  DetailMap.swift
//  DateSpot
//
//  Created by 신정섭 on 12/26/24.
//
import SwiftUI
import MapKit

struct DetailMapView : View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.465618, longitude: 127.0232), // LA 중심 좌표
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // 줌 레벨
    )
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            HStack {
                Text("Date Spots")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                Spacer()
                Image(systemName: "heart")
                    .foregroundColor(.red)
            }
            .padding()
            
            // 지도와 CardView
            ZStack {
                // 지도
                Map(coordinateRegion: $region)
                    .edgesIgnoringSafeArea(.all)
                
                // 위치 핀
                VStack {
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.red)
                        .offset(y: -100) // 핀 위치 조정
                    
                    Spacer()
                    
                    // 카드 뷰
                    DetailMapCardView()
                        .padding(.bottom, 80) // 카드뷰와 탭바 간격 조정
                }
            }
        }
    }
}

struct DetailMapCardView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("The Italian Corner")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "bookmark")
                            .foregroundColor(.black)
                        Text("231 • Italian")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\n")
                    
                    HStack {
                        Image(systemName: "pin")
                            .foregroundColor(.blue)
                        Text("123 Downtown St, Los Angeles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.green)
                        Text("11:00 AM - 10:00 PM")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.purple)
                        Text("(213) 555-0123")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 이미지 추가
                Image("2025 서울 카페&베이커리페어_1_공공1유형") // 프로젝트 내 이미지 파일 이름 사용
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 80)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}




#Preview{
    DetailMapView()
}
