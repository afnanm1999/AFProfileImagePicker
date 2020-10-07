// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AFProfileImagePicker",
    products: [
        .library(
            name: "AFProfileImagePicker",
            targets: ["AFProfileImagePicker"]),
    ],
    targets: [
        .target(
            name: "AFProfileImagePicker",
            dependencies: []),
        .testTarget(
            name: "AFProfileImagePickerTests",
            dependencies: ["AFProfileImagePicker"]),
    ]
)
