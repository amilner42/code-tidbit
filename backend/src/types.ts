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
  passwordDoesNotMatchConfirmPassword
}
