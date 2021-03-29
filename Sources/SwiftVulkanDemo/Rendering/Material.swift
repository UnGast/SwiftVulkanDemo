import Foundation
import Swim

public class Material {
  private let texture: Image<RGBA, UInt8>

  public init(texture: Image<RGBA, UInt8>) {
    self.texture = texture
  }

  public static func load(textureUrl: URL) throws -> Material {
    let texture = try Image<RGBA, UInt8>(contentsOf: textureUrl)
    return Material(texture: texture)
  }
}