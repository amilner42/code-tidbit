/// Module for handling app configuration through CLI arguments.

import * as yargs from "yargs";
import * as R from "ramda";

import { isNullOrUndefined, dropNullAndUndefinedProperties } from './util';


/**
 * All the meta configuration required for the application. All configuration
 * here is customizable through the CLI (this is what qualifies it as "meta").
 */
export interface AppConfig {
  mode: string,
  sessionSecretKey: string,
  sessionDuration: number,
  sessionCookieName: string,
  dbUrl: string
  port: number,
  isHttps: boolean
}

/**
 * Init `yargs` (singleton) for the CLI args.
 */
const argv =
  yargs
    .options({
      'mode': {
        demand: true,
        describe: "Choose a mode",
        choices: ["dev", "prod"],
        default: "dev",
        type: "string"
      },
      'session-secret-key': {
        demand: false,
        describe: "The secret session key is used by express-session",
        type: "string",
      },
      'session-duration': {
        demand: false,
        describe: "Specify the time before the session expires",
        type: "number"
      },
      'session-cookie-name': {
        demand: false,
        describe: "Specify the cookie name for the session.",
        type: "string"
      },
      'db-url': {
        demand: false,
        describe: "Set a specific db url",
        type: "string"
      },
      'port': {
        demand: false,
        describe: "Specify port that the app runs on",
        type: "number"
      },
      'is-https': {
        demand: false,
        describe: "Specify whether the app uses https or not",
        type: "boolean",
        default: undefined  // To prevent default (from being `false`)
      }
    })
    .argv;

/**
 * All the CLI args in `AppConfig` form.
 */
const cliArguments = <AppConfig>dropNullAndUndefinedProperties({
  mode: argv["mode"],
  sessionSecretKey: argv["session-secret-key"],
  sessionDuration: argv["session-duration"],
  sessionCookieName: argv["session-cookie-name"],
  dbUrl: argv["db-url"],
  port: argv["port"],
  isHttps: argv["is-https"]
});

/**
 * The default configuration for the backend.
 */
const defaultDevelopmentConfig: AppConfig = {
  mode: "dev",
  sessionSecretKey: "dev-secret-key",
  sessionDuration: 1000 * 60 * 60 * 24 * 365 * 10,
  sessionCookieName: "CodeTidbit",
  dbUrl: "mongodb://localhost:27017/CodeTidbit",
  port: 3000,
  isHttps: false
};

/**
 * Based on the CLI arguments returns the app configuration.
 *
 * NOTE: Will error if the CLI args are invalid. Passing 0 CLI args is
 *       completely valid and will result in dev mode with defaults.
 */
export const APP_CONFIG: AppConfig = (() => {

  // If in prod mode then certain optional CLI args are required.
  if(cliArguments.mode == "prod") {

    const missingRequiredProdFlags = R.any(
      isNullOrUndefined,
      [
        cliArguments.sessionSecretKey,
        cliArguments.dbUrl,
        cliArguments.port,
        cliArguments.isHttps
      ]
    );

    if(missingRequiredProdFlags) {
      throw Error("Ran in prod mode but did not provide required CLI args!");
    }
  }

  return R.merge(defaultDevelopmentConfig, cliArguments);
})();
