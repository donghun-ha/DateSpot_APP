// UserView.swift
// DateSpot
//
// Created by 하동훈 on 27/12/2024.
//
// 이 뷰는 사용자의 기본 프로필 정보를 보여주는 간소화된 화면입니다.
// 회색 기본 프로필 이미지와 사용자 이름, 설정 아이콘을 포함합니다.
// 사용자에게 편안한 메시지를 제공하여 사용자 경험을 개선합니다.

import SwiftUI

struct UserView: View {
    var username: String = "daytrip-fiqmonpsy"  // 사용자 이름
    var profileImage: Image = Image(systemName: "person.crop.circle.fill")  // iOS 기본 제공 회색 프로필 이미지

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    // 프로필 이미지
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                        .padding(.leading, 20)
                    
                    Spacer()
                    
                    // 설정 버튼
                    Button(action: {
                        // 설정 화면으로 이동
                    }) {
                        Image(systemName: "gear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 20)
                    }
                }
                .padding(.top, 30)

                // 사용자 이름
                Text(username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Spacer()

                // 인사 메시지
                Text("새로운 경험을 탐험하세요")
                    .font(.headline)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding()

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

// 미리보기 제공
struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView()
    }
}
