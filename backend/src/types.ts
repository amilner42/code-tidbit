/// Module for all typings specific to the app.

import { ObjectID } from "mongodb";
import { Request, Response, NextFunction } from "express";

/**
 * To make the code more clear, we have route handlers return a promise to their
 * value, if the handler resolves then we 200 the result back to the server, if
 * it errors we 400 the error back to the server.
 */
export type RouteHandler = (req: Request, res: Response, next: NextFunction) => Promise<any>;

/**
 * Format of the application's routes.
 */
export interface AppRoutes {
  [routeUrl: string]: {
    [methodType: string]: RouteHandler;
  }
}

/**
 * Often used in responses when we just want to return an ID.
 */
export interface TargetID {
  targetID: MongoObjectID;
}

/**
 * A basic response containing just a message.
 */
export interface BasicResponse {
  message: string;
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
 * An alias for a mongo `ObjectID`.
 */
export type MongoObjectID = ObjectID;

/**
 * An alias for a `string`, representing a mongoID in string form.
 */
export type MongoStringID = string;

/**
 * A mongo ID in either string-form or ObjectID-form.
 */
export type MongoID = MongoStringID | MongoObjectID;

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
  storyInvalidTidbitType,
  storyEmptyTag,
  storyNoTags,
  storyDoesNotExist,
  storyEditorMustBeAuthor,
  storyAddingNonExistantTidbit,
  snipbitDescriptionTooLong,
  bigbitDescriptionTooLong
}
