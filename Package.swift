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
        .package(name: "CSDL2", url: "https://github.com/UnGast/CSDL2.git", .branch("master")),
        .package(name: "Vulkan", url: "https://github.com/UnGast/SwiftVulkan.git", .branch("master")),
        .package(name: "Swim", url: "https://github.com/t-ae/swim.git", .branch("master")),
        .package(name: "GfxMath", url: "https://github.com/UnGast/swift-gfx-math.git", .branch("master")),
        .package(url: "https://github.com/cx-org/CombineX.git", .branch("master")),
        .package(name: "SwiftGUI", path: "../../swift-gui"),
        .package(path: "../SwiftGUIBackendSkia"),
        .package(name: "FirebladeECS", url: "https://github.com/fireblade-engine/ecs.git", from: "0.17.4")
    ],
    targets: [
        .target(
            name: "SwiftVulkanDemo",
            dependencies: [
                "Vulkan",
                "Swim",
                "CTinyObjLoader",
                "GfxMath",
                "CSDL2",
                "CombineX",
                .product(name: "CSDL2Vulkan", package: "CSDL2"),
                "SwiftGUI",
                .product(name: "SwiftGUIBackendSkia", package: "SwiftGUIBackendSkia"),
                .product(name: "ApplicationBackendSDL2", package: "SwiftGUI"),
                .product(name: "ApplicationBackendSDL2Vulkan", package: "SwiftGUI"),
                "FirebladeECS"],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [.define("ENABLE_VULKAN")]
        ),
        .target(name: "CTinyObjLoader")
    ]
)
