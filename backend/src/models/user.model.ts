/// Module for encapsulating helper functions for the user model.

import { omit } from "ramda";
import * as kleen from "kleen";

import { renameIDField, collection, ID } from '../db';
import { malformedFieldError, dropNullAndUndefinedProperties } from "../util";
import { nonEmptyStringSchema, optional } from "./kleen-schemas";
import { MongoID, ErrorCode } from '../types';


/**
 * A `User` (as seen in the database).
 */
export interface User {
  _id?: MongoID;
  id?: MongoID;
  name: string;
  email: string;
  password: string;
  bio: string;
}

/**
 * When registering a new user into the database. The user need not provide all
 * of the values themselves, we may set default values manually. Anything with a
 * `?` we set ourselves.
 */
export interface UserForRegistration {
  name: string,
  email: string,
  password: string,
  bio?: string
}

/**
 * When logging in a returning user will need to provide these 2 values.
 */
export interface UserForLogin {
  email: string,
  password: string
}

/**
 * Used for updating a user.
 */
export interface UserUpdateObject {
  name: string,
  bio: string
}

/**
 * The schema for updating a user.
 */
const updateUserSchema: kleen.objectSchema = {
  objectProperties: {
    "name": optional(
      nonEmptyStringSchema(
        { errorCode: ErrorCode.invalidName, message: "Name cannot be empty."},
        malformedFieldError("name")
      )
    ),
    "bio": optional(
      nonEmptyStringSchema(
        { errorCode: ErrorCode.invalidBio, message: "Bio cannot be empty" },
        malformedFieldError("bio")
      )
    )
  },
  typeFailureError: malformedFieldError("User Update Object")
};

/**
 * Prepares the user for response.
 *  - Removes password
 *  - Rename `_id` to `id`
 */
export const prepareUserForResponse = (user: User) => {
  delete user.password;
  renameIDField(user);
  return user;
};

/**
 * All db helpers for a user.
 */
export const userDBActions = {

  /**
   * Updates the basic informaton connected to a user.
   */
  updateUser: (userID, userUpdateObject: UserUpdateObject): Promise<User> => {
    return kleen.validModel(updateUserSchema)(userUpdateObject)
    .then(() => {
      return collection("users");
    })
    .then((UserCollection) => {
      return UserCollection.findOneAndUpdate(
        { _id: ID(userID) },
        { $set: dropNullAndUndefinedProperties(userUpdateObject) },
        { returnOriginal: false }
      );
    })
    .then((updatedUserResult) => {
      if(updatedUserResult.value) {
        return prepareUserForResponse(updatedUserResult.value);
      }

      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "We couldn't find your account."
      });
    });
  }
};
