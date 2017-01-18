/// Module for encapsulating helper functions for the user model.

import { omit } from "ramda";

import { Model, MongoID } from '../types';


/**
 * A `User`.
 */
export interface User {
  _id?: MongoID;
  email: string;
  password?: string;
}

/**
 * The `User` model.
 */
export const userModel: Model<User> = {
  name: "user",
  stripSensitiveDataForResponse: omit(['password', '_id'])
};
