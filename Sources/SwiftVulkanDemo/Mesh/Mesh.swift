import GfxMath

public class Mesh {
  var vertices: [Vertex]
  var indices: [UInt32]
  var material: Material?

  public init(vertices: [Vertex], indices: [UInt32], material: Material? = nil) {
    self.vertices = vertices
    self.indices = indices
    self.material = material
  }
}