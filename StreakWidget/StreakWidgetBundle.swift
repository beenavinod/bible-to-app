//
//  StreakWidgetBundle.swift
//  StreakWidget
//
//  Created by Beena Vinod on 11/04/26.
//

import WidgetKit
import SwiftUI

@main
struct StreakWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        StreakWidgetControl()
        StreakWidgetLiveActivity()
    }
}
