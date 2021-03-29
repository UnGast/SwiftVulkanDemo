import GfxMath

public class GameObject {
  var transformation: FMat4 = .identity
  var children: [GameObject] = []
}