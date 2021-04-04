import Foundation
import GfxMath
import Vulkan

public struct Vertex: BufferSerializable {
  public var position: FVec3
  public var normal: FVec3
  public var color: Color
  public var texCoord: FVec2

  public init(position: FVec3, normal: FVec3 = .zero, color: Color = .white, texCoord: FVec2 = .zero) {
    self.position = position
    self.normal = normal
    self.color = color
    self.texCoord = texCoord
  }

  public var serializedData: [Float] {
    position.elements + normal.elements + [
      Float(color.r) / 255,
      Float(color.g) / 255,
      Float(color.b) / 255,
      Float(color.a) / 255
    ] + texCoord.elements
  }

  public static var inputBindingDescription: VertexInputBindingDescription {
    VertexInputBindingDescription(
      binding: 0,
      stride: UInt32(MemoryLayout<Float>.size * 12),
      inputRate: .vertex
    )
  }

  public static var inputAttributeDescriptions: [VertexInputAttributeDescription] {
    [
      VertexInputAttributeDescription(
        location: 0,
        binding: 0,
        format: .R32G32B32_SFLOAT,
        offset: 0
      ),
      VertexInputAttributeDescription(
        location: 1,
        binding: 0,
        format: .R32G32B32_SFLOAT,
        offset: UInt32(MemoryLayout<Float>.size * 3)
      ),
      VertexInputAttributeDescription(
        location: 2,
        binding: 0,
        format: .R32G32B32A32_SFLOAT,
        offset: UInt32(MemoryLayout<Float>.size * 6)
      ),
      VertexInputAttributeDescription(
        location: 3,
        binding: 0,
        format: .R32G32_SFLOAT,
        offset: UInt32(MemoryLayout<Float>.size * 10)
      )
    ]
  }
}
/*
public struct Position2 {
  public var x: Float
  public var y: Float
}

public struct Position3 {
  public var x: Float
  public var y: Float
  public var z: Float
}

public struct Color {
  public var r: Float
  public var g: Float
  public var b: Float
}*/