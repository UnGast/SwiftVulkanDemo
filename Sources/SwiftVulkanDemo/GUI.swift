import SwiftGUI
import SwiftGUIBackendSkia

class GUI {
  var surface: CpuBufferDrawingSurface? {
    didSet {
      updateDrawingContext()
    }
  }
  @Deferred private var root: Root
  private var drawingContext: DrawingContext?

  private var data = Array(repeating: "Hello World!", count: 10)

  public init() {
    root = Root(rootWidget: Container().with(styleProperties: {
      (\.$foreground, .white)
    }).withContent {
      Container().with(styleProperties: {
        (\.$width, 400)
        (\.$height, 400)
        (\.$background, .yellow)
      })

      Button().with(styleProperties: {
        (\.$background, .red)
        (\.$padding, Insets(all: 16))
      }).withContent {
        Text("Hello World!").with(styleProperties: {
          (\.$foreground, .white)
        })
      }

      List(items: ImmutableBinding(get: { [unowned self] in data })).withContent {
        List<String>.itemSlot {
          Text($0)
        }
      }
    })
    root.setup(
      measureText: { [unowned self] in drawingContext?.measureText(text: $0, paint: $1) ?? .zero },
      getKeyStates: { KeyStatesContainer() },
      getApplicationTime: { 0 },
      getRealFps: { 0 },
      requestCursor: { _ in {} })
  }

  private func updateDrawingContext() {
    if let surface = surface {
      let backend = SkiaCpuDrawingBackend(surface: surface)
      drawingContext = DrawingContext(backend: backend)
      root.bounds.size = DSize2(surface.size)
    } else {
      drawingContext = nil
    }
  }

  func update() {
    root.tick(Tick(deltaTime: 0, totalTime: 0))
    if let drawingContext = drawingContext {
      root.draw(drawingContext)
    }
  }
}