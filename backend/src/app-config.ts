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
 * All the CLI options [for the yargs library].
 */
const yargsOptions =
  {
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
      requiredForProd: true
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
      type: "string",
      requiredForProd: true
    },
    'port': {
      demand: false,
      describe: "Specify port that the app runs on",
      type: "number",
      requiredForProd: true
    },
    'is-https': {
      demand: false,
      describe: "Specify whether the app uses https or not",
      type: "boolean",
      default: undefined,  // To prevent default (from being `false`)
      requiredForProd: true
    }
  }

/**
 * Init `yargs` (singleton) for the CLI args.
 */
const argv = yargs.options(yargsOptions).argv;

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
  port: 3001,
  isHttps: false
};

/**
 * Based on the CLI arguments and the defaults returns the app configuration.
 *
 * NOTE: Will error if the CLI args are invalid. Passing 0 CLI args is completely valid and will result in dev mode with
 *       defaults. But if you run in "prod" mode there are required flags.
 *
 * NOTE: This immediete-invocation of the lambda will log the CLI arguments once.
 */
export const APP_CONFIG: AppConfig = (() => {

  /**
   * Logging CLI arguments.
   */
  console.log("CLI Arguments");
  let missingProdFlags = false;
  for(let option in yargsOptions) {
    const mentionDevDefault = (option === "mode" && argv[option] === "dev") ? " [DEFAULT]" : "";
    const missingProdFlag =
        argv["mode"] === "prod" && yargsOptions[option].requiredForProd === true && argv[option] === undefined;
    console.log(` - ${option}: ${argv[option]}${mentionDevDefault}${missingProdFlag ? " [MISSING PROD FLAG]" : ""}`);

    if(missingProdFlag) {
      missingProdFlags = true;
    }
  }
  console.log("\n");
  if(missingProdFlags) { throw new Error("Missing Prod Flags"); }

  const cliInitialValues = R.merge(defaultDevelopmentConfig, cliArguments);

  // Logging initial arguments passed to app (cliArguments merged with defaults).
  console.log("Initial Arguments");
  for(let cliArgName in cliInitialValues) {
    console.log(` - ${cliArgName}: ${cliInitialValues[cliArgName]}`);
  }
  console.log("\n");

  return cliInitialValues;
})();
