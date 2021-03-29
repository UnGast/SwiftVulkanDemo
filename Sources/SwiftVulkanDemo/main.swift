import Foundation
import SwiftGUI
import ApplicationBackendSDL2
import ApplicationBackendSDL2Vulkan
import FirebladeECS

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

var gameObjects = [GameObject]()

let vikingRoom = MeshGameObject(mesh: try! Mesh.loadObj(fileUrl: Bundle.module.url(forResource: "viking_room", withExtension: "obj")!))
vikingRoom.transformation = FMat4([
  1, 0, 0, 10,
  0, 1, 0, 5,
  0, 0, 1, 0,
  0, 0, 0, 1
])
gameObjects.append(vikingRoom)
gameObjects.append(MeshGameObject(mesh: Mesh.plane(size: FVec2(100, 100))))

var nextCubeIndex = 0

func createNewCube() {
  let gameObject = MeshGameObject(mesh: Mesh.cuboid())
  gameObject.transformation = FMat4([
    1, 0, 0, Float(nextCubeIndex),
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
  ])
  gameObjects.append(gameObject)

  nextCubeIndex += 1
}

createNewCube()
try renderer.updateRenderData(gameObjects: gameObjects)

var lastLoopTime = Date.timeIntervalSinceReferenceDate
var lastNewCubeTime = Date.timeIntervalSinceReferenceDate

func mainLoop() throws {
  let startTime = Date.timeIntervalSinceReferenceDate
  if startTime - lastNewCubeTime > 1 {
    createNewCube()
    try renderer.updateRenderData(gameObjects: gameObjects)
    print("ADD NEW")
    lastNewCubeTime = startTime
  }
  lastLoopTime = startTime

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
    case let event as WindowMouseButtonDownEvent:
      backend.relativeMouseModeEnabled = true
    case let event as WindowKeyDownEvent:
      let speed = Float(0.5)
      switch event.key {
        case .arrowUp:
          renderer.camera.position += renderer.camera.forward * speed
        case .arrowDown:
          renderer.camera.position -= renderer.camera.forward * speed
        case .arrowRight:
          renderer.camera.position += renderer.camera.right * speed
        case .arrowLeft:
          renderer.camera.position -= renderer.camera.right * speed
        case .escape:
          backend.relativeMouseModeEnabled = false
        default:
          break
      }
  default:
    print("unused window event", event)
  }
}