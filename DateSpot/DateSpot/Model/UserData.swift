//
//  Signin.swift
//  DateSpot
//
//  Created by mac on 12/30/24.
//

import RealmSwift
import SwiftUI

class UserData: Object {
    @Persisted(primaryKey: true) var _id: ObjectId   // primary key로 지정
    @Persisted var userEmail: String
    @Persisted var userName: String =  "" // 로그인한 사용자 이름
    @Persisted var userImage: String =  "" // 로그인한 사용자 이름
    
    convenience init(userEmail: String, userName: String = "", userImage: String = "" ) {
        self.init()
        self.userEmail = userEmail
        self.userName = userName
        self.userImage = userImage
    }
}
