public class SceneDrawData {
  public var vertices: [Vertex] = []
  public var indices: [UInt32] = []
  public var meshDrawInfos: [MeshDrawInfo] = []
}

public struct MeshDrawInfo {
  public var mesh: Mesh
  public var indicesStartIndex: UInt32
  public var indicesCount: UInt32
}