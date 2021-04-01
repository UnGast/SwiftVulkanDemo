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

let gui = GUI(surface: CpuBufferDrawingSurface(size: ISize2(800, 800)))
gui.update()

let windowSizeSubscription = window.sizeChanged.sink {
  try! renderer.recreateSwapchain()
  gui.surface = CpuBufferDrawingSurface(size: $0)
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
  print("ADDED CUBE")

  nextCubeIndex += 1
}

createNewCube()

let guiPlane = MeshGameObject(mesh: Mesh(vertices: [
  Vertex(position: FVec3(-1, 1, 0.1), color: .transparent, texCoord: FVec2(0, 1)),
  Vertex(position: FVec3(1, 1, 0.1), color: .transparent, texCoord: FVec2(1, 1)),
  Vertex(position: FVec3(1, -1, 0.1), color: .transparent, texCoord: FVec2(1, 0)),
  Vertex(position: FVec3(-1, -1, 0.1), color: .transparent, texCoord: FVec2(0, 0)),
], indices: [
  0, 1, 2,
  0, 2, 3
]))
guiPlane.projectionEnabled = false

/*let pixelData = gui.surface.buffer.withMemoryRebound(to: UInt8.self, capacity: 1) {
  UnsafeBufferPointer(start: $0, count: gui.surface.size.width * gui.surface.size.height * 4)
}
var guiMaterial = Material(texture: Image(width: gui.surface.size.width, height: gui.surface.size.height, rgba: Array(pixelData)))
guiPlane.mesh.material = guiMaterial*/
/*guiPlane.transformation = Matrix4([
  1, 0, 0, 10,
  0, 1, 0, 0,
  0, 0, 1, 0, 
  0, 0, 0, 1
]).matmul(Matrix4(topLeft: Quaternion(angle: 90, axis: FVec3(1, 0, 0)).mat3).transposed)*/
gameObjects.append(guiPlane)

var lastLoopTime = Date.timeIntervalSinceReferenceDate
var lastNewCubeTime = Date.timeIntervalSinceReferenceDate

createNewCube()
createNewCube()
createNewCube()

func mainLoop() throws {
  let startTime = Date.timeIntervalSinceReferenceDate
  if startTime - lastNewCubeTime > 1 {
    createNewCube()
    print("ADD NEW")
    lastNewCubeTime = startTime
  }
  print("FPS", 1 / (startTime - lastLoopTime))
  lastLoopTime = startTime

  try backend.processEvents()

  if let oldMaterial = guiPlane.mesh.material {
    try renderer.materialSystem.removeMaterial(material: oldMaterial)
  }
  gui.update()
  let pixelData = gui.surface.buffer.withMemoryRebound(to: UInt8.self, capacity: 1) {
    UnsafeBufferPointer(start: $0, count: gui.surface.size.width * gui.surface.size.height * 4)
  }
  guiPlane.mesh.material = Material(texture: Image(width: gui.surface.size.width, height: gui.surface.size.height, rgba: Array(pixelData)))
  
  try renderer.drawFrame(gameObjects: gameObjects)

  DispatchQueue.main.async {
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