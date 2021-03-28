import FirebladeECS

public class RenderMesh: Component {
  public var mesh: Mesh

  public init(_ mesh: Mesh) {
    self.mesh = mesh
  }
}
