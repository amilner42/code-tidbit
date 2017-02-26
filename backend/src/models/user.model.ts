/// Module for encapsulating helper functions for the user model.

import { omit } from "ramda";
import * as kleen from "kleen";

import { malformedFieldError } from "../util";
import { nonEmptyStringSchema, optional } from "./kleen-schemas";
import { Model, MongoID, ErrorCode } from '../types';


/**
 * A `User` (as seen in the database).
 */
export interface User {
  _id?: MongoID;
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
 * The `User` model.
 */
export const userModel: Model<User> = {
  name: "user",
  stripSensitiveDataForResponse: omit(['password', '_id'])
};


/**
 * The schema for updating a user.
 */
export const updateUserSchema: kleen.objectSchema = {
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
