//
//  BookMarkView.swift
//  DateSpot
//
//  Created by 하동훈 on 26/12/2024.
//

import SwiftUI

struct BookMarkView: View {
    @State private var isSheetPresented = false // 바텀시트 표시 여부
    @State private var bookmarkLists: [BookmarkList] = [] // 폴더(리스트) 저장
    @State private var unsortedItems: [BookmarkItem] = [ // 초기 저장된 항목
        BookmarkItem(name: "TripImage 1", imageName: "tripImage1", isBookmarked: true),
        BookmarkItem(name: "TripImage 2", imageName: "tripImage2", isBookmarked: true),
        BookmarkItem(name: "TripImage 3", imageName: "tripImage3", isBookmarked: true),
        BookmarkItem(name: "TripImage 4", imageName: "tripImage4", isBookmarked: true)
    ]
    @State private var selectedList: BookmarkList? = nil // 선택된 리스트
    @State private var showDeleteAlert = false // 폴더 삭제 경고 표시
    @State private var folderToDelete: BookmarkList? = nil // 삭제할 폴더

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // "새 리스트 만들기" 버튼
                    Text("내 리스트")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack {
                        Button(action: {
                            isSheetPresented = true // 바텀시트 열기
                        }) {
                            VStack {
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                                Text("새 리스트 만들기")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 150, height: 150)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(bookmarkLists) { list in
                                    Button(action: {
                                        selectedList = list // 폴더 선택
                                    }) {
                                        VStack {
                                            Image(systemName: "folder.fill")
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.blue)
                                            Text(list.name)
                                                .font(.footnote)
                                                .foregroundColor(.primary)
                                        }
                                        .frame(width: 100, height: 100)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                    .contextMenu { // 폴더 롱프레스 메뉴
                                        Button(role: .destructive) {
                                            folderToDelete = list
                                            showDeleteAlert = true
                                        } label: {
                                            Text("삭제하기")
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 저장한 공간 섹션
                    VStack(alignment: .leading, spacing: 10) {
                        Text("저장한 공간")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if unsortedItems.isEmpty {
                            Text("저장된 항목이 없습니다.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        } else {
                            ForEach(unsortedItems) { item in
                                HStack {
                                    ZStack(alignment: .topTrailing) {
                                        Image(item.imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(10)
                                        
                                        Button(action: {
                                            toggleBookmark(for: item) // 북마크 토글
                                        }) {
                                            Image(systemName: item.isBookmarked ? "bookmark.fill" : "bookmark")
                                                .foregroundColor(.white)
                                                .padding(8)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text("저장된 공간에서 항목을 관리하세요.")
                                            .font(.footnote)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        print("\(item.name) 클릭됨")
                                    }) {
                                        Text("보기")
                                            .font(.footnote)
                                            .padding(8)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                            .cornerRadius(5)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("공간")
            .sheet(isPresented: $isSheetPresented) {
                AddListSheet(isSheetPresented: $isSheetPresented, bookmarkLists: $bookmarkLists, unsortedItems: $unsortedItems)
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("폴더 삭제"),
                    message: Text("\(folderToDelete?.name ?? "폴더")를 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("삭제")) {
                        deleteFolder(folderToDelete)
                    },
                    secondaryButton: .cancel()
                )
            }
            .background(
                NavigationLink(destination: FolderDetailView(list: selectedList), isActive: Binding(
                    get: { selectedList != nil },
                    set: { if !$0 { selectedList = nil } }
                )) {
                    EmptyView()
                }
            )
        }
    }
    
    // 북마크 토글 함수
    private func toggleBookmark(for item: BookmarkItem) {
        if let index = unsortedItems.firstIndex(where: { $0.id == item.id }) {
            unsortedItems[index].isBookmarked.toggle()
            if !unsortedItems[index].isBookmarked {
                unsortedItems.remove(at: index)
            }
        }
    }
    
    // 폴더 삭제 함수
    private func deleteFolder(_ folder: BookmarkList?) {
        guard let folder = folder else { return }
        bookmarkLists.removeAll { $0.id == folder.id }
    }
}

// 데이터 모델
struct BookmarkList: Identifiable {
    let id = UUID()
    let name: String
    var items: [BookmarkItem] = []
}

struct BookmarkItem: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    var isBookmarked: Bool // 북마크 여부
}

// 바텀시트: 리스트 추가 UI
struct AddListSheet: View {
    @Binding var isSheetPresented: Bool
    @Binding var bookmarkLists: [BookmarkList]
    @Binding var unsortedItems: [BookmarkItem]
    @State private var newListName: String = "" // 새 리스트 이름
    @State private var selectedItems: [BookmarkItem] = [] // 선택한 항목
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("새 리스트 만들기")
                    .font(.headline)
                    .padding()
                
                TextField("리스트 이름을 입력하세요", text: $newListName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                List(unsortedItems) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        if selectedItems.contains(where: { $0.id == item.id }) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .onTapGesture {
                        if selectedItems.contains(where: { $0.id == item.id }) {
                            selectedItems.removeAll { $0.id == item.id }
                        } else {
                            selectedItems.append(item)
                        }
                    }
                }
                
                Button(action: {
                    // 새 리스트 생성 및 항목 이동
                    let newList = BookmarkList(name: newListName, items: selectedItems)
                    bookmarkLists.append(newList)
                    unsortedItems.removeAll { item in
                        selectedItems.contains(where: { $0.id == item.id })
                    }
                    isSheetPresented = false // 바텀시트 닫기
                }) {
                    Text("리스트 생성")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                .disabled(newListName.isEmpty) // 입력값이 없으면 버튼 비활성화
                
                Spacer()
            }
            .navigationTitle("새 리스트")
        }
    }
}

struct FolderDetailView: View {
    var list: BookmarkList? // 선택된 폴더(리스트)
    
    var body: some View {
        VStack {
            if let list = list {
                Text("\(list.name) 리스트")
                    .font(.headline)
                    .padding()
                
                if list.items.isEmpty {
                    Text("이 리스트에 항목이 없습니다.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(list.items) { item in
                            HStack {
                                Image(item.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("리스트 항목 관리 중")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            } else {
                Text("리스트를 선택하세요.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .navigationTitle(list?.name ?? "리스트")
    }
}

#Preview {
    BookMarkView()
}
