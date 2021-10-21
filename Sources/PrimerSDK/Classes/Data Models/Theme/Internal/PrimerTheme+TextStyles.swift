internal struct TextStyle {
    let `default`, title, subtitle, amountLabel, system, error: TextTheme

    static func `default`(with data: TextStyleData) -> TextStyle {
        return TextStyle(
            default: TextTheme.default(with: data.default),
            title: TextTheme.title(with: data.title),
            subtitle: TextTheme.subtitle(with: data.subtitle),
            amountLabel: TextTheme.amountLabel(with: data.amountLabel),
            system: TextTheme.system(with: data.system),
            error: TextTheme.error(with: data.error)
        )
    }
}

internal struct TextTheme {
    let color: UIColor
    let fontSize: Int

    static func `default`(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Black,
            fontSize: data.fontSize ?? Fontsize.Default
        )
    }

    static func title(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Black,
            fontSize: data.fontSize ?? Fontsize.Title
        )
    }

    static func subtitle(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Gray,
            fontSize: data.fontSize ?? Fontsize.Subtitle
        )
    }

    static func amountLabel(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Black,
            fontSize: data.fontSize ?? Fontsize.AmountLabel
        )
    }

    static func system(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Blue,
            fontSize: data.fontSize ?? Fontsize.System
        )
    }

    static func error(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Red,
            fontSize: data.fontSize ?? Fontsize.Error
        )
    }
}
