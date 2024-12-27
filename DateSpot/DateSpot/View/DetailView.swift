import SwiftUI

struct DetailView: View {
//    let restaurant: Restaurant
    
    var images = ["2025 서울 카페&베이커리페어_1_공공1유형", "2025 서울 카페&베이커리페어_2_공공1유형", "2025 서울 카페&베이커리페어_3_공공1유형", "2025 서울 카페&베이커리페어_4_공공1유형"] // 이미지 배열
    @State private var selection: Int = 0 // 현재 페이지 인덱스 추적
    @State private var showTipView = false // 팝업 표시 여부
    @StateObject private var viewModel = RatingViewModel() // ViewModel 초기화
    @State private var rates: Int = 0 // StarRatingView와 바인딩할 별점 값
    
    private let fullDescription = """
        카페&베이커리페어는 카페 창업주와 바이어를 대상으로 한 전문 전시회로, 카페 운영에 필요한 원두, 로스팅 머신, 장비, 인테리어 소품 등 다양한 품목을 선보인다. 전시회에는 커피머신과 장비 판매업체, 원두 납품업체 등 관련 기업들이 주로 참가하며, 방문객은 전시 제품을 체험하고 구매할 수 있다. 카페 관련 최신 트렌드를 한자리에서 확인할 수 있어 카페 창업을 준비하거나 업계 종사자들에게 유익한 기회가 된다. 또한 바리스타 대회, 디저트 대회 등 다양한 부대행사가 진행되어 볼거리가 풍성하다. 매년 새로운 대회와 프로그램이 마련되니 미리 일정을 확인하고 방문하는 것이 좋다.
        """
    @State private var aboutTextPosition: CGRect = .zero
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // 상단 Navigation Bar 대체
                HStack {
                    Button(action: {
                        // 뒤로 가기 버튼 동작
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .bold))
                    }
                    Spacer()
                    Text("Date Spots")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal)
                ZStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // 스와이프 가능한 이미지 뷰
                            ZStack {
                                ZStack(alignment: .bottomTrailing) {
                                    InfinitePageView(
                                        selection: $selection,
                                        before: { $0 == 0 ? images.count - 1 : $0 - 1 },
                                        after: { $0 == images.count - 1 ? 0 : $0 + 1 }
                                    ) { index in
                                        GeometryReader { geometry in
                                            Image(images[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: geometry.size.width, height: 250)
                                                .clipped()
                                        }
                                        .frame(height: 250)
                                    }
                                    .frame(height: 250)
                                    
                                    // 인디케이터 (1/4 형식) - 오른쪽 아래로 이동
                                    Text("\(selection + 1)/\(images.count)")
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        .padding([.trailing, .bottom], 16) // 오른쪽 아래로 이동
                                }
                                .frame(height: 250)
                                
                                // Heart 아이콘
                                Button(action: {
                                }) {
                                    Image(systemName: "heart")
                                        .foregroundColor(.white)
                                        .font(.system(size: 30))
                                    
                                }
                                .padding([.trailing, .top], 16) // 아이콘 위치
                                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            }
                            
                            // 주요 정보
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("서울 카페&베이커리페어")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Button(action: {
                                    }) {
                                        HStack {
                                            Image(systemName: "paperplane.fill")
                                                .foregroundColor(.white)
                                                .frame(width: 10, height: 10, alignment: .leading)
                                            Spacer()
                                            Text("Navigate")
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 90, height: 10, alignment: .trailing)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    }
                                }
                                Text("명소")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                if let rating = viewModel.ratings.first { // 테스트를 위해 첫 번째 데이터만 사용
                                    StarRatingView(rating: Binding(
                                        get: {
                                            rates // 현재 별점
                                        },
                                        set: { newRating in
                                            rates = newRating // 새 별점 설정
                                            Task {
                                                var updatedRating = rating
                                                updatedRating.evaluation = Double(newRating)
                                                try? await viewModel.updateRating(updatedRating) // 서버 업데이트
                                            }
                                        }
                                    ))
                                        .frame(height: 20)
                                        .onAppear {
                                            rates = Int(rating.evaluation) // 초기 값 설정
                                            }
                                        } else {
                                            Text("Loading...") // 데이터가 없는 경우 표시
                                        }
                                    }
                                    .onAppear {
                                        viewModel.fetchRatings() // 데이터 가져오기
                                    }
                                    
                                HStack(spacing: 10) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.blue)
                                        Text("9:00 AM - 6:00 PM")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.blue)
                                    Text("서울특별시 강남구 남부순환로 3104 (대치동)SETEC")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                        .lineLimit(nil) // 텍스트 줄바꿈 허용
                                        .fixedSize(horizontal: false, vertical: true) // 텍스트 폭에 맞춰 자동 크기 조정
                                }
                            }
                            .padding()
                            // 설명
                            ZStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("About")
                                            .font(.headline)
                                            .background(GeometryReader { geometry in
                                                // About 텍스트 위치 저장
                                                Color.clear.onAppear {
                                                    self.aboutTextPosition = geometry.frame(in: .global)
                                                }
                                            })
                                        Spacer()
                                        Button(action: {
                                            showTipView.toggle() // TipView 표시/숨김 토글
                                        }) {
                                            Image(systemName: "info.circle")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal)
                                    // 모델 데이터로 수정 필요
                                    Text("카페&베이커리페어는 카페 창업주와 바이어를 대상으로 한 전문 전시회로, 카페 운영에 필요한 원두, 로스팅 머신, 장비, 인테리어 소품 등 다양한 품목을 선보인다.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(3) // 최대 3줄로 제한
                                        .truncationMode(.tail) // 텍스트가 잘릴 경우 말줄임표 추가
                                        .padding(.horizontal)
                                    Spacer()
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            // 모델 데이터로 수정 필요
                                            Text("Nearby Places")
                                                .font(.headline)
                                            Spacer()
                                            Button(action: {
                                                // 전체 보기 동작
                                            }) {
                                                HStack(spacing: 4) { // 텍스트와 아이콘 간 간격 조정
                                                    Text("View all")
                                                        .foregroundColor(.blue)
                                                        .font(.subheadline)
                                                    Image(systemName: "arrow.right")
                                                        .foregroundColor(.blue)
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                // 모델 데이터로 수정 필요
                                                VStack {
                                                    Image("royal-gardens")
                                                        .resizable()
                                                        .frame(width: 100, height: 100)
                                                        .cornerRadius(8)
                                                    Text("Royal Gardens")
                                                        .font(.subheadline)
                                                    Text("0.3 miles away")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                // 모델 데이터로 수정 필요
                                                VStack {
                                                    Image("historic-cafe")
                                                        .resizable()
                                                        .frame(width: 100, height: 100)
                                                        .cornerRadius(8)
                                                    Text("Historic Café")
                                                        .font(.subheadline)
                                                    Text("0.5 miles away")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        if showTipView {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("서울 카페& 베이커리 페어")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Button(action: {
                                        showTipView = false // TipView 닫기
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                            .padding(8)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                }
                                Text(fullDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                            .frame(maxWidth: 370)
                            .padding()
                            .position(x: aboutTextPosition.midX + 160, y: aboutTextPosition.maxY-650) // About 기준 위치
                            .transition(.opacity)
                            .animation(.easeInOut, value: showTipView)
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }

#Preview {
    DetailView()
}
