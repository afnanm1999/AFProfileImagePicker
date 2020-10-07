// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AFProfileImagePicker",
    products: [
        .library(
            name: "AFProfileImagePicker",
            targets: ["AFProfileImagePicker"]),
    ],
    dependencies: [
        .package(name: "MMSCameraViewController",
                 url: "git@github.com:afnanm1999/MMSCameraViewController.git",
                 .branch("SPM-Integration"))
    ],
    targets: [
        .target(
            name: "AFProfileImagePicker",
            dependencies: ["MMSCameraViewController"],
            resources: [.copy("Assets/Localized.strings")]),
    ]
)
