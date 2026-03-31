//
//  OrinWidgetsBundle.swift
//  OrinWidgets
//
//  Created by Garrett Spencer on 3/24/26.
//

import WidgetKit
import SwiftUI

@main
struct OrinWidgetsBundle: WidgetBundle {
    var body: some Widget {
        OrinWidgets()
        OrinWidgetsControl()
        OrinWidgetsLiveActivity()
    }
}
