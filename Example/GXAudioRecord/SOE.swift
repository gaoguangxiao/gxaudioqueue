//
//  SOE.swift
//  GXAudioRecord_Example
//
//  Created by 高广校 on 2024/10/16.
//  Copyright © 2024 gaoguangxiao. All rights reserved.
//

import Foundation
import RSAdventureApi

@objcMembers
public class SOE: NSObject {
    
    let recordSOE = TencentSOE()
 
    func startSOE() {
        recordSOE.reloadTIMTokenCount = 3
        Task {
            let (code, data) = await recordSOE.startRecord()
            if code == 0 {
                PrivateInfo.shareInstance().secretKey = data.tmpSecretKey
            }
//            print(data)
        }
    }
}
