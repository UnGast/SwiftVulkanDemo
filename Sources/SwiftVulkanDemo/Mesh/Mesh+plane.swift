import GfxMath

extension Mesh {
  public static func plane(size: FVec2) -> Mesh {
    Mesh(vertices: [
      Vertex(position: FVec3(x: -size.x, y: 0, z: size.y), color: Color(r: 1, g: 255, b: 1, a: 1), texCoord: FVec2(x: 0, y: 0)),
      Vertex(position: FVec3(x: size.x, y: 0, z: size.y), color: Color(r: 1, g: 255, b: 1, a: 255), texCoord: FVec2(x: 1, y: 0)),
      Vertex(position: FVec3(x: size.x, y: 0, z: -size.y), color: Color(r: 1, g: 1, b: 1, a: 255), texCoord: FVec2(x: 1, y: 1)),
      Vertex(position: FVec3(x: -size.x, y: 0, z: -size.y), color: Color(r: 1, g: 1, b: 1, a: 255), texCoord: FVec2(x: 0, y: 1))
    ], indices: [
      0, 1, 2, 
      0, 2, 3
    ])
  }
}