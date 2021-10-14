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
    let fontsize: Int

    static func `default`(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Text.Default,
            fontsize: data.fontsize ?? Fontsize.Default
        )
    }

    static func title(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Text.Title,
            fontsize: data.fontsize ?? Fontsize.Title
        )
    }

    static func subtitle(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Text.Subtitle,
            fontsize: data.fontsize ?? Fontsize.Subtitle
        )
    }

    static func amountLabel(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Text.AmountLabel,
            fontsize: data.fontsize ?? Fontsize.AmountLabel
        )
    }

    static func system(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Text.System,
            fontsize: data.fontsize ?? Fontsize.System
        )
    }

    static func error(with data: TextThemeData) -> TextTheme {
        return TextTheme(
            color: data.defaultColor ?? Colors.Text.Error,
            fontsize: data.fontsize ?? Fontsize.Error
        )
    }
}
