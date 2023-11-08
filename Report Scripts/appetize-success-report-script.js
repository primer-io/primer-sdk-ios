const fs = require('fs');
const smb = require('slack-message-builder')

const SUCCESS_SUMMARY_FILE_PATH = '/var/tmp/appetize-success-link-summary.json'

createAppetizeSummaryReport(process.argv[3])

async function createAppetizeSummaryReport(branch) {
    fs.writeFileSync(SUCCESS_SUMMARY_FILE_PATH, JSON.stringify(createAppetizeSummary(branch)));
}

function createAppetizeSummary(branch) {
    return smb()
        .attachment()
        .mrkdwnIn(["title"])
        .color("#36a64f")
        .title(`Successfully generated Appetize link for branch ${branch}.`)
        .authorName(process.env.GITHUB_ACTOR)
        .authorLink(`${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_ACTOR}`)
        .authorIcon(`${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_ACTOR}.png?size=32`)
        .field()
        .title("Appetize URL")
        .value(`<${process.env.APPETIZE_APP_URL}|${process.env.APPETIZE_APP_URL.slice(-6)}>`)
        .short(true)
        .end()
        .field()
        .title("Livedemostore URL")
        .value(`<${process.env.LIVEDEMOSTORE_URL}>`)
        .short(true)
        .end()
        .field()
        .title("Ref")
        .value(process.env.GITHUB_REF)
        .short(true)
        .end()
        .field()
        .title("Actions URL")
        .value(
            `<${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/actions/runs/${process.env.GITHUB_RUN_ID}|${process.env.GITHUB_WORKFLOW}>`
        )
        .short(true)
        .end()
        .field()
        .title("Commit")
        .value(
            `<${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/commit/${process.env.GITHUB_SHA}|${process.env.GITHUB_SHA.slice(0,6)}>`
        )
        .short(true)
        .end()
        .field()
        .title("Platform")
        .value("iOS")
        .short(true)
        .end()
        .end()
        .json()
}
