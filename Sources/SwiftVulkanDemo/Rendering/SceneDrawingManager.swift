import Vulkan

public class SceneDrawingManager {
  private let vulkanRenderer: VulkanRenderer
  public var sceneDrawInfo: SceneDrawInfo

  public init(vulkanRenderer: VulkanRenderer) throws {
    self.vulkanRenderer = vulkanRenderer

    self.sceneDrawInfo = SceneDrawInfo()
    self.sceneDrawInfo.vertexBuffer = try ManagedBuffer(vulkanRenderer: vulkanRenderer, usageFlags: .vertexBuffer)
    self.sceneDrawInfo.indexBuffer = try ManagedBuffer(vulkanRenderer: vulkanRenderer, usageFlags: .indexBuffer)
  }

  public func update(gameObjects: [GameObject]) throws {
    for gameObject in gameObjects {
      if sceneDrawInfo.gameObjectDrawInfos[gameObject] != nil {
        continue
      }

      if let meshGameObject = gameObject as? MeshGameObject {
        let vertexOffset = try sceneDrawInfo.vertexBuffer.addChunk(meshGameObject.mesh.vertices.flatMap { $0.data }, rawCount: meshGameObject.mesh.vertices.count)
        let indicesStartIndex = try sceneDrawInfo.indexBuffer.addChunk(meshGameObject.mesh.indices)

        sceneDrawInfo.gameObjectDrawInfos[gameObject] = GameObjectDrawInfo(
          materialDrawData: vulkanRenderer.materialSystem.materialRenderData[ObjectIdentifier(vulkanRenderer.mainMaterial)]!,
          vertexOffset: vertexOffset,
          indicesStartIndex: indicesStartIndex
        )
      }
    }
  }
}