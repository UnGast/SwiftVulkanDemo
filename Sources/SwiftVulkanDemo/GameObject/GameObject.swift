import GfxMath

public class GameObject {
  var transformation: FMat4 = .identity
  var projectionEnabled = true
  var children: [GameObject] = []
}