const axios = require('axios');
const fs = require('fs');
const path = require('path');
const i18nStringsFiles = require('i18n-strings-files');

require('dotenv').config();

const { PHRASE_ACCESS_KEY, PHRASE_PROJECT_ID } = process.env;

const LOCALIZABLE_PATH = path.join(__dirname, '../../Sources/PrimerSDK/Resources/Localizable/');
const DEFAULT_LOCALIZABLE_PATH = path.join(LOCALIZABLE_PATH, 'en.lproj');
const TRANSLATION_FILES = ["Localizable.strings"];
const PHRASE_LOCALES_PATH = path.join(__dirname, 'temp');

const phraseRequestInstance = axios.create({
  baseURL: `https://api.phrase.com/v2/projects/${PHRASE_PROJECT_ID}`,
  headers: { Authorization: `token ${PHRASE_ACCESS_KEY}` },
});

const parseJson = (filePath) => {
  const rawData = fs.readFileSync(filePath);
  const data = JSON.parse(rawData);
  return data;
};

const saveJson = (filePath, data) => {
  const rawData = JSON.stringify(data, null, 2);
  fs.writeFileSync(filePath, rawData);
};

const ensureDirectoryExistence = (filePath) => {
  const dirname = path.dirname(filePath);
  if (fs.existsSync(dirname)) {
    return;
  }

  ensureDirectoryExistence(dirname);
  fs.mkdirSync(dirname);
};

const formatTranslationString = (translation) => {
  return translation
    .replace(/'/g, "\\'")
    .replace(/"/g, '\\"');
};

const saveLocalizableStrings = (filePath, data) => {
  ensureDirectoryExistence(filePath);
  i18nStringsFiles.writeFileSync(filePath, data, { encoding: 'UTF-16', wantsComments: true });
};

const getLocales = () =>
  phraseRequestInstance.get('/locales', { params: { page: 1, per_page: 100 } });

const getDictionary = (localeId) =>
  phraseRequestInstance.get(`/locales/${localeId}/download`, {
    params: { file_format: 'simple_json' },
  });

const downloadPhrase = async () => {
  console.log('Querying locales...');
  const { data: unsortedLocales } = await getLocales();
  const locales = unsortedLocales.filter((locale) => !locale.default);

  console.log(`${locales.length} locales to download`);
  fs.rmdirSync(PHRASE_LOCALES_PATH, { recursive: true });

  ensureDirectoryExistence(path.join(PHRASE_LOCALES_PATH, 'test.json'));
  for (let i = 0; i < locales.length; ++i) {
    const locale = locales[i];
    console.log(
      `\t${i + 1}/${locales.length} - ${locale.code}: Downloading...`,
    );

    const { data: translation } = await getDictionary(locale.id);
    const filePath = path.join(PHRASE_LOCALES_PATH, `${locale.code}.json`);
    saveJson(filePath, translation);
  }
};

const getOriginalLocale = (originalLanguagePath) => {
  return i18nStringsFiles.readFileSync(originalLanguagePath,
    { encoding: 'UTF-16', wantsComments: true });
};

const extractTranslations = () => {
  TRANSLATION_FILES.forEach((f) => {
    console.log(`Extracting translations for ${f}...`);

    const originalLocale = getOriginalLocale(path.join(DEFAULT_LOCALIZABLE_PATH, f));

    const processLocale = (sourceLocalePath) => {
      const basename = path.basename(sourceLocalePath);
      const sourceLocale = parseJson(sourceLocalePath);

      // Keep the comments
      const destinationLocale = Object.keys(originalLocale).reduce((acc, key) => {
        acc[key] = { }
        acc[key].text = sourceLocale[key] || originalLocale[key].text
        acc[key].comment = originalLocale[key].comment
        return acc;
      }, {});

      const localeName = basename.split('.json')[0];
      const valuesPath = path.join(LOCALIZABLE_PATH, `${localeName}.lproj`);
      const destinationLocalePath = path.join(valuesPath, f);
      console.log(`\t${basename} -> ${destinationLocalePath}`);

      saveLocalizableStrings(destinationLocalePath, destinationLocale);
    };

    fs.readdirSync(PHRASE_LOCALES_PATH).forEach((file) => {
      if (path.extname(file) !== '.json') {
        return;
      }

      processLocale(path.join(PHRASE_LOCALES_PATH, file));
    });
  });

};

(async () => {
  if (!process.argv.includes('--ignore-download')) {
    await downloadPhrase();
  }

  await extractTranslations();
})();
