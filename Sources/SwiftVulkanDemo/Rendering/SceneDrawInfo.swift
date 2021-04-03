import GfxMath
import Vulkan

public class SceneDrawInfo {
  public var vertices: [Vertex] = []
  public var indices: [UInt32] = []
  public var meshDrawInfos: [MeshDrawInfo] = []
  public var gameObjectDrawInfos: [GameObject: GameObjectDrawInfo] = [:]

  @Deferred var vertexBuffer: ManagedBuffer
  @Deferred var indexBuffer: ManagedBuffer
}

public struct MeshDrawInfo {
  public var mesh: Mesh
  public var materialRenderData: MaterialRenderData
  public var transformation: FMat4
  public var projectionEnabled: Bool
  public var indicesStartIndex: UInt32
  public var indicesCount: UInt32
}

public struct GameObjectDrawInfo {
  public var materialDrawData: MaterialRenderData
  public var vertexOffset: Int
  public var indicesStartIndex: Int
}