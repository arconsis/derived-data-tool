//
//  StyleGenerator.swift
//
//
//  Created by Moritz Ellerbrock on 08.05.23.
//

import Foundation
import SwiftHtml

enum StyleGenerator {
    @TagBuilder
    static func colorScheme() -> Tag {
        Text("""
                     ":root {
                     --color-night: rgb(12, 9, 13);
                     --color-high: rgb(0, 205, 51);
                     --color-normal: rgb(0, 0, 0);
                     --color-medium: rgb(255, 174, 0);
                     --color-low: rgb(224, 26, 79);
                     }
        """)
    }

    @TagBuilder
    static func textWeight(_ weight: Int = 700) -> Tag {
        Text("""
        .text_weight {
                    font-weight: \(weight);
                }
        """)
    }

    enum CssColors: String {
        case night
        case high
        case normal
        case medium
        case low

        var value: String {
            switch self {
            case .night: return "--color-night"
            case .high: return "--color-high"
            case .normal: return "--color-normal"
            case .medium: return "--color-medium"
            case .low: return "--color-low"
            }
        }
    }

    @TagBuilder
    static func textColor(_ color: CssColors) -> Tag {
        Text("""
                .text_color_\(color.rawValue) {
                color: var(\(color.value);
                }
        """)
    }

    @TagBuilder
    static func tableHeader(height: Int = 40,
                            top: Int = 0,
                            right: Int = 0,
                            bottom: Int = 0,
                            left: Int = 0) -> Tag
    {
        Text("""
                th {
                height: \(height)px;
                padding: \(top)px \(right)px \(bottom)px \(left)px;
                }
        """)
    }

    enum TextSize: String {
        case large
        case larger
        case medium
        case small
        case smaller
        case xLarge = "x-large"
        case xSmall = "x-small"
        case xxLarge = "xx-large"
        case xxSmall = "xx-small"
    }

    @TagBuilder
    static func textSize(_ size: TextSize) -> Tag {
        Text("""
                .text_size {
                    font-size: \(size.rawValue);
                }
        """)
    }
}

/*

 body>div>h1 {
 text-align: center;
 padding-bottom: 32px;
 }

 /* TABLE STYLE */
 .top5 {
 background-color: rgb(255, 255, 255);
 }

 .last5 {
 background-color: rgb(255, 255, 255);
 }

 .top5changes {
 background-color: rgb(255, 255, 255);
 }

 .last5changes {
 background-color: rgb(255, 255, 255);
 }

 .listall {
 margin: 16px;
 width: 95%;
 }

 th {
 height: 40px;
 padding: 0px 4px 0px 4px;
 }

 td {
 padding: 8px;
 }

 .no_bottom_line {
 position: absolute;
 border-bottom: 0px;
 bottom: -15px;
 font-size: larger;
 }

 th,
 td {
 border-bottom: 1px solid #ddd;
 }

 .text_center {
 text-align: center;
 }

 .tablewrapper {
 overflow-x: auto;
 }

 .toplist {
 width: auto;
 }

 .toplist > table {
 margin: 16px;
 }

 .header_rank_name {
 font-size: xx-large;
 }

 .header_coverage {

 }

 main {
 display: grid;
 justify-content: center;
 align-content: center;
 gap: 1rem;
 grid-template-columns: repeat(auto-fill, minmax(24em, auto));
 }

 main>section {
 margin: auto;
 padding: auto;
 }

 */
