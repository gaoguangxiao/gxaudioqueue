////
////  SOE.swift
////  GXAudioRecord_Example
////
////  Created by 高广校 on 2024/10/16.
////  Copyright © 2024 gaoguangxiao. All rights reserved.
////
//
//import Foundation
//import RSAdventureApi
//
//public typealias ClosureDataComplete = (_ code: Int) -> Void
//
//@objcMembers
//public class SOE: NSObject {
//    
//    let recordSOE = TencentSOE()
// 
//    func startSOE(block: @escaping ClosureDataComplete) {
//        recordSOE.reloadTIMTokenCount = 3
//        Task {
//            let (code, data) = await recordSOE.startRecord()
//            let priInfo = PrivateInfo.shareInstance()
//            if code == 0 {
//                priInfo?.secretId = data.tmpSecretId
//                priInfo?.secretKey = data.tmpSecretKey
//                priInfo?.token = data.token
//            }
//            block(code)
//        }
//    }
//}
