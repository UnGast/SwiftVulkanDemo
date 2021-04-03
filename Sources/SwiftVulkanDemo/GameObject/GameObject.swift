import GfxMath

public class GameObject: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }

  public static func == (lhs: GameObject, rhs: GameObject) -> Bool {
    lhs === rhs
  }

  var transformation: FMat4 = .identity
  var projectionEnabled = true
  var children: [GameObject] = []

}