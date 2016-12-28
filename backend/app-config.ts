/// Module for app encapsulating app configuration.

/**
 * Config for the backend.
 */
export const APP_CONFIG = {
  "app": {
    "secondsBeforeReloginNeeded": 1000 * 60 * 60 * 24 * 365 * 10,
    "expressSessionSecretKey": "someSecretKeyHere", // #CHANGE4PROD
    "expressSessionCookieName": "CodeTidbit",
    "isHttps": false, // #CHANGE4PROD
    "port": 3000,
    "apiSuffix": "/api"
  },
  "db": {
    "url": "mongodb://localhost:27017/CodeTidbit" // #CHANGE4PROD
  }
}
