import Foundation
import CVulkan
import HID
import GfxMath

Platform.initialize()
print("Platform version: \(Platform.version)")

// either use a custom surface sub-class
// or use the default implementation directly
// let surface = CPUSurface()
let window = try Window(properties: WindowProperties(title: "Title", frame: .init(0, 0, 800, 600)),
                        surfaceType: VLKWindowSurface.self)

func createVulkanInstance() throws -> VkInstance {
    var hidSurfaceExtensions = try! VLKWindowSurface.getInstanceExtensionNames(in: window)

    // strdup copies the string passed in and returns a pointer to copy; copy not managed by swift -> not deallocated
    var enabledLayerNames = [UnsafePointer<CChar>(strdup("VK_LAYER_KHRONOS_validation"))]

    var createInfo = VkInstanceCreateInfo(
        sType: VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        pNext: nil,
        flags: 0,
        pApplicationInfo: nil,
        enabledLayerCount: UInt32(enabledLayerNames.count),
        ppEnabledLayerNames: enabledLayerNames,
        enabledExtensionCount: UInt32(hidSurfaceExtensions.count),
        ppEnabledExtensionNames: &hidSurfaceExtensions
    )

    var instanceOpt: VkInstance?
    let result = vkCreateInstance(&createInfo, nil, &instanceOpt)

    guard let instance = instanceOpt, result == VK_SUCCESS else {
        throw VulkanApplicationError.couldNotCreateInstance
    }

    return instance
}

let vulkanInstance = try createVulkanInstance()

enum VulkanApplicationError: Error {
    case couldNotCreateInstance
}

try window.setupSurface(surfaceOptions: VLKWindowSurface.Options(instance: vulkanInstance))


// rendering/content setup
// -----------------

let surface = try window.surface

let renderer = try VulkanRenderer(window: window)

/*let gui = GUI(surface: CpuBufferDrawingSurface(size: ISize2(800, 800)))
gui.update()*/

var gameObjects = [GameObject]()

// this mesh seems to help to fix some strange behavior where the second mesh vertices
// overwrite the first ones in the vulkan buffer
gameObjects.append(MeshGameObject(mesh: Mesh(vertices: [Vertex(position: .zero, color: .white, texCoord: .zero)], indices: [0])))

let vikingRoom = MeshGameObject(mesh: try! Mesh.loadObj(fileUrl: Bundle.module.url(forResource: "viking_room", withExtension: "obj")!))
vikingRoom.transformation = FMat4([
  1, 0, 0, 10,
  0, 1, 0, 5,
  0, 0, 1, 0,
  0, 0, 0, 1
])
gameObjects.append(vikingRoom)

gameObjects.append(MeshGameObject(mesh: Mesh.plane(size: FVec2(100, 100))))

let xyzDragon = MeshGameObject(mesh: try! Mesh.loadObj(fileUrl: Bundle.module.url(forResource: "xyzrgb_dragon", withExtension: "obj")!))
gameObjects.append(xyzDragon)

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
/*
let guiPlane = MeshGameObject(mesh: Mesh(vertices: [
  Vertex(position: FVec3(-1, 1, 0.1), color: .transparent, texCoord: FVec2(0, 1)),
  Vertex(position: FVec3(1, 1, 0.1), color: .transparent, texCoord: FVec2(1, 1)),
  Vertex(position: FVec3(1, -1, 0.1), color: .transparent, texCoord: FVec2(1, 0)),
  Vertex(position: FVec3(-1, -1, 0.1), color: .transparent, texCoord: FVec2(0, 0)),
], indices: [
  0, 1, 2,
  0, 2, 3
]))
guiPlane.projectionEnabled = false*/

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
//gameObjects.append(guiPlane)

var lastLoopTime = Date.timeIntervalSinceReferenceDate
var lastNewCubeTime = Date.timeIntervalSinceReferenceDate

createNewCube()
createNewCube()
createNewCube()


// application loop
// ------------------

var event = Event()

var quit = false

while !quit {
    Events.pumpEvents()

    while Events.pollEvent(&event) {
        switch event.variant {
        case .userQuit:
            quit = true

        default:
            break
        }
    }
}

Platform.quit()
/*
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

  /*if let oldMaterial = guiPlane.mesh.material {
    try renderer.materialSystem.removeMaterial(material: oldMaterial)
  }
  gui.update()
  let pixelData = gui.surface.buffer.withMemoryRebound(to: UInt8.self, capacity: 1) {
    UnsafeBufferPointer(start: $0, count: gui.surface.size.width * gui.surface.size.height * 4)
  }
  guiPlane.mesh.material = Material(texture: Image(width: gui.surface.size.width, height: gui.surface.size.height, rgba: Array(pixelData)))*/
  
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
      if backend.relativeMouseModeEnabled {
        renderer.camera.yaw += Float(event.positionDelta.x)
        renderer.camera.pitch -= Float(event.positionDelta.y)
        renderer.camera.pitch = min(89, max(-89, renderer.camera.pitch))
      }

      gui.root.consume(RawMouseMoveEvent(position: DPoint2(event.position), previousPosition: DPoint2(event.position - event.positionDelta)))
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
}*/