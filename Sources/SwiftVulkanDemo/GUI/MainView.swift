import SwiftGUI

class MainView: ContentfulWidget {
  private var data = Array(repeating: "Hello World!", count: 10)

  @DirectContentBuilder override var content: DirectContent {
    Container().with(styleProperties: {
      (\.$foreground, .white)
    }).withContent {
      Container().with(styleProperties: {
        (\.$width, 400)
        (\.$height, 400)
        (\.$background, .yellow)
      })

      Button().with(styleProperties: {
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
    }
  }

  override public var style: Style {
    Style("&") {} nested: {
      FlatTheme(primaryColor: .blue, secondaryColor: .red, backgroundColor: .black).styles
    }
  }
}