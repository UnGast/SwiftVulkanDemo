// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftVulkanDemo",
    products: [
        .executable(
            name: "SwiftVulkanDemo",
            targets: ["SwiftVulkanDemo"]),
    ],
    dependencies: [
        .package(name: "Vulkan", path: "../SwiftVulkan"),
        .package(name: "Swim", url: "https://github.com/t-ae/swim.git", .branch("master")),
        .package(name: "GfxMath", url: "https://github.com/UnGast/swift-gfx-math.git", .branch("master")),
        .package(url: "https://github.com/cx-org/CombineX.git", .branch("master")),
        //.package(name: "SwiftGUI", path: "../../swift-gui"),
        //.package(path: "../SwiftGUIBackendSkia"),
        .package(name: "Fireblade", path: "../FirebladeEngine"),
        .package(url: "https://github.com/nicklockwood/Euclid.git", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        .target(
            name: "SwiftVulkanDemo",
            dependencies: [
                "Vulkan",
                "Swim",
                "CTinyObjLoader",
                "GfxMath",
                "CombineX",
                //.product(name: "CSDL2Vulkan", package: "CSDL2"),
                //"SwiftGUI",
                //.product(name: "SwiftGUIBackendSkia", package: "SwiftGUIBackendSkia"),
                //.product(name: "ApplicationSDL2", package: "SwiftGUI"),
                //.product(name: "ApplicationSDL2Vulkan", package: "SwiftGUI"),
                .product(name: "FirebladeHID", package: "Fireblade"),
                "Euclid"],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [.define("ENABLE_VULKAN")]
        ),
        .target(name: "CTinyObjLoader")
    ]
)
