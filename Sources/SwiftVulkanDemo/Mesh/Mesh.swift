import GfxMath

public class Mesh {
  var vertices: [Vertex]
  var indices: [UInt32]

  public init(vertices: [Vertex], indices: [UInt32]) {
    self.vertices = vertices
    self.indices = indices
  }
}