import Sentry

class SentryService {
    init() {
        SentrySDK.start { options in
                options.dsn = "https://cf465e26dea34b92b275336044751485@o498025.ingest.sentry.io/5575862"
                options.debug = true // Enabled debug when first installing is always helpful
            }
    }
}
