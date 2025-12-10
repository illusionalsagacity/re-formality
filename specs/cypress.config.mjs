import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    baseUrl: "http://localhost:8085",
    video: false,
    specPattern: "tests/**/*.js",
    screenshotsFolder: "screenshots",
    fixturesFolder: "fixtures",
    pluginsFile: "plugins/index.js",
    supportFile: "support/index.js",
  },
});
