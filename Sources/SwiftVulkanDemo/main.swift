import Foundation
import SwiftGUI
import ApplicationBackendSDL2
import ApplicationBackendSDL2Vulkan

let backend = try ApplicationBackendSDL2.getInstance()
let applicationEventSubscription = backend.eventPublisher.sink(receiveValue: handleApplicationEvent)

let applicationBackend = try ApplicationBackendSDL2.getInstance()

let window = SDL2VulkanWindow(initialSize: ISize2(800, 600))

//SDL_SetRelativeMouseMode(SDL_TRUE)
let windowInputEventSubscription = window.inputEventPublisher.sink(receiveValue: handleWindowInputEvent)

let renderer = try VulkanRenderer(window: window)

let windowSizeSubscription = window.sizeChanged.sink { _ in
  try! renderer.recreateSwapchain()
}

func mainLoop() throws {
  try backend.processEvents()

  try renderer.drawFrame()

  DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
    try! mainLoop()
  }
}

try mainLoop()
dispatchMain()

func handleApplicationEvent(_ event: ApplicationEvent) {
  switch event {
  case .quit:
    exit(0)
  default:
    print("APPLCIATION EVENT", event)
  }
}

func handleWindowInputEvent(_ event: WindowInputEvent) {
  switch event {
    case let event as WindowMouseMoveEvent:
      renderer.camera.yaw += Float(event.positionDelta.x)
      renderer.camera.pitch -= Float(event.positionDelta.y)
      renderer.camera.pitch = min(89, max(-89, renderer.camera.pitch))
  default:
    print("WINDOW EVENt", event)
  }
}