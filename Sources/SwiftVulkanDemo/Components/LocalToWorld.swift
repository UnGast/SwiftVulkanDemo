import FirebladeECS
import GfxMath

public class LocalToWorld: Component {
  public var transformationMatrix: FMat4

  public init(transformationMatrix: FMat4) {
    self.transformationMatrix = transformationMatrix
  }
}