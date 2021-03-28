# SwiftVulkanDemo

A demo application for using Swift and Vulkan. Tested on Ubuntu 20.04. Porting to other platforms should be possible.

Here is the library for the Vulkan bindings for Swift: [SwiftVulkan](https://github.com/UnGast/SwiftVulkan)

This is the current output of the demo application:

<img src="Docs/Assets/screenshot.png?raw=true" width="500">

Note that on the plane a GUI is rendered. This is done with [SwiftGUI](https://github.com/UnGast/swift-gui) and the [SwiftGUIBackendSkia](https://github.com/UnGast/SwiftGUIBackendSkia). The GUI is rendered to a texture which is then applied to the plane.