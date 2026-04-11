//
//  LockScreenIconWidgetBundle.swift
//  LockScreenIconWidget
//
//  Created by Beena Vinod on 11/04/26.
//

import WidgetKit
import SwiftUI

@main
struct LockScreenIconWidgetBundle: WidgetBundle {
    var body: some Widget {
        LockScreenIconWidget()
        LockScreenIconWidgetControl()
        LockScreenIconWidgetLiveActivity()
    }
}
