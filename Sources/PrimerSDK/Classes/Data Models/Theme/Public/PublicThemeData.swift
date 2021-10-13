public class PrimerThemeData {
    public var colors: ColorSwatchData?
    public var view: ViewThemeData?
    public var text: TextStyleData?
    public var buttons: ButtonStyleData?
    public var input: InputThemeData?
}

public class ButtonStyleData {
    public var main: ButtonThemeData?
    public var paymentMethod: ButtonThemeData?
    // TODO: add more
}

public class ButtonThemeData {
    public var defaultColor: UIColor?
    public var disabledColor: UIColor?
    public var errorColor: UIColor?
    public var text: TextThemeData?
    public var border: BorderThemeData?
    public var cornerRadius: CGFloat?
}

public class ViewThemeData {
    public var backgroundColor: UIColor?
    public var cornerRadius: CGFloat?
    public var safeMargin: CGFloat?
}

public class TextStyleData {
    public var `default`: TextThemeData?
    public var title: TextThemeData?
    public var subtitle: TextThemeData?
    public var amountLabel: TextThemeData?
    public var system: TextThemeData?
    public var error: TextThemeData?
}

public class TextThemeData {
    public var defaultColor: UIColor?
    public var fontsize: Int?
}

public class BorderThemeData {
    public var defaultColor: UIColor?
    public var selectedColor: UIColor?
    public var errorColor: UIColor?
    public var width: CGFloat?
}

public class InputThemeData {
    public var backgroundColor: UIColor?
    public var text: TextThemeData?
    public var border: BorderThemeData?
    public var cornerRadius: CGFloat?
}

public class ColorSwatchData {
    public var primary: UIColor?
    public var error: UIColor?
}
