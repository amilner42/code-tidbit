/// Module for encapsulating helper functions for the user model.

import { omit } from "ramda";

import { model, user } from '../types';


/**
 * The `user` model.
 */
export const userModel: model<user> = {
  name: "user",
  stripSensitiveDataForResponse: omit(['password', '_id'])
};
