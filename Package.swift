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
        .package(name: "SwiftGUI", url: "https://github.com/UnGast/swift-gui.git", .branch("master")),
        .package(path: "../SwiftGUIBackendSkia")
    ],
    targets: [
        .target(
            name: "SwiftVulkanDemo",
            dependencies: [
                "CSDL2",
                "CVulkan",
                "Vulkan",
                "CSDL2Vulkan",
                "Swim",
                "CTinyObjLoader",
                "GfxMath",
                "SwiftGUI",
                .product(name: "SwiftGUIBackendSkia", package: "SwiftGUIBackendSkia"),
                .product(name: "ApplicationBackendSDL2", package: "SwiftGUI")],
            resources: [
                .copy("Resources")
            ]
        ),
        .target(name: "CTinyObjLoader")
    ]
)
