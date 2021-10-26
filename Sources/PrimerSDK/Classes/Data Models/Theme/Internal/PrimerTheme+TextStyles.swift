internal struct TextStyle {
    let body, title, subtitle, amountLabel, system, error: TextTheme

    static func build(with data: TextStyleData) -> TextStyle {
        return TextStyle(
            body: TextTheme.body(with: data.body),
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

    static func body(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.black,
            fontSize: data.fontSize ?? Fontsize.default
        )
    }

    static func title(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.black,
            fontSize: data.fontSize ?? Fontsize.title
        )
    }

    static func subtitle(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.gray,
            fontSize: data.fontSize ?? Fontsize.subtitle
        )
    }

    static func amountLabel(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.black,
            fontSize: data.fontSize ?? Fontsize.amountLabel
        )
    }

    static func system(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.blue,
            fontSize: data.fontSize ?? Fontsize.system
        )
    }

    static func error(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.red,
            fontSize: data.fontSize ?? Fontsize.error
        )
    }
}
