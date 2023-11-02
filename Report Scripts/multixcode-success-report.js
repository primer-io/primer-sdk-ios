const fs = require('fs');
const smb = require('slack-message-builder')

const SUCCESS_SUMMARY_FILE_PATH = '/var/tmp/multixcode-success-summary.json'

createMultiXcodeSummaryReport(process.argv[3], process.argv[4], process.argv[5])

async function createMultiXcodeSummaryReport(branch, xcodeVersions, integrationTypes) {
  fs.writeFileSync(SUCCESS_SUMMARY_FILE_PATH, JSON.stringify(createMultiXcodeSummary(branch, xcodeVersions, integrationTypes)));
}

function createMultiXcodeSummary(branch, xcodeVersions, integrationTypes) {
  return smb()
      .attachment()
      .mrkdwnIn(["title"])
      .color("#36a64f")
      .title(`Successfully build on multiple Xcode Versions`)
      .authorName(process.env.GITHUB_ACTOR)
      .authorLink(`${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_ACTOR}`)
      .authorIcon(`${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_ACTOR}.png?size=32`)
      .field()
      .title("Xcode Versions")
      .value(`${xcodeVersions}`)
      .short(true)
      .end()
      .field()
      .title("Integration Types")
      .value(`${integrationTypes}`)
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