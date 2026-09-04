import * as Sentry from "@sentry/node";

if (process.env.SENTRY_ENABLED === "true") {
    if (!process.env.SENTRY_DSN) {
        throw new Error("SENTRY_ENABLED is true but SENTRY_DSN is not set");
    }

    Sentry.init({
        dsn: process.env.SENTRY_DSN,
        dataCollection: {
            userInfo: false,
            genAI: {
                inputs: false,
                outputs: false,
            },
            cookies: false,
        },

        enableLogs: process.env.SENTRY_ENABLE_LOGS === "true",

        tracesSampleRate: Number(process.env.SENTRY_TRACES_SAMPLE_RATE) || 0.1,
    });
}
