/// Module for all typings specific to the app.

import { Handler } from "express";


/**
 * Format of the application's routes.
 */
export interface AppRoutes {
  [routeUrl: string]: {
    [methodType: string]: Handler;
  }
}

/**
 * Format for specifiying if authenticaton is required for routes.
 */
export interface AppRoutesAuth {
  [routeUrl: string]: {
    [methodType: string]: boolean;
  }
};

/**
 * The error format that the frontend expects.
 */
export interface FrontendError {
  errorCode: number;
  message: string;
}

/**
 * A language from the database.
 */
export interface Language {
  _id?: MongoID;
  // The encoded language from the frontend type union, eg. "Javascript".
  encodedName: string;
}

/**
 * A mongo ID.
 */
export type MongoID = string;

/**
 * All models (in `/models`) should export an implementation of this
 * interface.
 */
export interface Model<T> {

  /**
   * Unique name, should be identical to the name of interface `T`.
   */
  name: string;

  /**
   * Prior to responding to an HTTP request with a model, this method should
   * be called to strip sensitive data, eg you don't wanna be sending the
   * user his data with the password attached.
   */
  stripSensitiveDataForResponse: (model: T) => T;
}

/**
 * All ErrorCode are used for simpler programmatic communication between the
 * client and server.
 *
 * NOTE An identical enum should be kept on the frontend/backend.
 *
 * NOTE Always add new errors to the bottom of the list.
 */
export enum ErrorCode {
  youAreUnauthorized = 1,
  emailAddressAlreadyRegistered,
  noAccountExistsForEmail,
  incorrectPasswordForEmail,
  phoneNumberAlreadyTaken,
  invalidMongoID,
  invalidEmail,
  invalidPassword,
  internalError,                    // For errors that are not handleable
  passwordDoesNotMatchConfirmPassword,
  snipbitEmptyRange,
  snipbitEmptyComment,
  snipbitNoHighlightedComments,
  snipbitEmptyConclusion,
  snipbitEmptyIntroduction,
  snipbitEmptyCode,
  snipbitNoTags,
  snipbitEmptyTag,
  snipbitEmptyDescription,
  snipbitEmptyName,
  snipbitNameTooLong,
  snipbitInvalidLanguage,
  invalidName,
  snipbitDoesNotExist,
  bigbitEmptyRange,
  bigbitEmptyComment,
  bigbitEmptyFilePath,
  bigbitEmptyName,
  bigbitNameTooLong,
  bigbitEmptyDescription,
  bigbitEmptyTag,
  bigbitNoTags,
  bigbitEmptyIntroduction,
  bigbitEmptyConclusion,
  bigbitNoHighlightedComments,
  bigbitInvalidLanguage,
  bigbitDoesNotExist,
  invalidBio,
  storyNameEmpty,
  storyNameTooLong,
  storyDescriptionEmpty,
  storyDescriptionTooLong,
  storyInvalidPageType
}
