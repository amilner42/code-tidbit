/// Module for all typings specific to the app.

import { Handler } from "express";


/**
 * Format of the application's routes.
 */
export interface appRoutes {
  [routeUrl: string]: {
    [methodType: string]: Handler;
  }
}

/**
 * A `user`.
 */
export interface user {
  _id?: string;
  email: string;
  password?: string;
}


/**
 * All models (in `/models`) should export an implementation of this
 * interface.
 */
export interface model<T> {

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
 * All errorCodes for simpler programmatic communication between the client and
 * server.
 *
 * NOTE An identical enum should be kept on the frontend/backend.
 */
export enum errorCodes {
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
