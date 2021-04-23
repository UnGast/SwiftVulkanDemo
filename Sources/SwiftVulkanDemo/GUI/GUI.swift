/*import SwiftGUI
import SwiftGUIBackendSkia

class GUI {
  var surface: CpuBufferDrawingSurface {
    didSet {
      updateDrawingContext()
    }
  }
  @Deferred public var root: Root
  @Deferred private var drawingContext: DrawingContext

  public init(surface: CpuBufferDrawingSurface) {
    self.surface = surface

    root = Root(rootWidget: MainView())

    self.updateDrawingContext()

    root.setup(
      measureText: { [unowned self] in drawingContext.measureText(text: $0, paint: $1) ?? .zero },
      getKeyStates: { KeyStatesContainer() },
      getApplicationTime: { 0 },
      getRealFps: { 0 },
      requestCursor: { _ in {} })
  }

  private func updateDrawingContext() {
    let backend = SkiaCpuDrawingBackend(surface: surface)
    drawingContext = DrawingContext(backend: backend)
    root.bounds.size = DSize2(surface.size)
  }

  func update() {
    root.tick(Tick(deltaTime: 0, totalTime: 0))
    root.draw(drawingContext)
  }
}*/