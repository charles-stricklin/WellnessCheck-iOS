// swift-tools-version: 5.9
//
//  Package.swift
//  WellnessCheckShared
//
//  Created: v0.7.0 (2026-01-20)
//
//  By Charles Stricklin, Stricklin Development, LLC
//
//  Local Swift package containing shared code between iOS and watchOS targets.
//  This ensures models and types stay in sync across platforms.
//

import PackageDescription

let package = Package(
    name: "WellnessCheckShared",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "WellnessCheckShared",
            targets: ["WellnessCheckShared"]
        ),
    ],
    targets: [
        .target(
            name: "WellnessCheckShared",
            dependencies: []
        ),
    ]
)
