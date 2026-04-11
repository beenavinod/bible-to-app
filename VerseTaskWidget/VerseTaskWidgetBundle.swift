//
//  VerseTaskWidgetBundle.swift
//  VerseTaskWidget
//
//  Created by Beena Vinod on 11/04/26.
//

import WidgetKit
import SwiftUI

@main
struct VerseTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
        VerseTaskWidget()
        VerseTaskWidgetControl()
        VerseTaskWidgetLiveActivity()
    }
}
