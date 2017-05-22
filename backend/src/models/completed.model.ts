/// Module for encapsulating helper functions for the completed model.

import * as kleen from "kleen";

import { TidbitPointer, tidbitPointerSchema } from "./tidbit.model";
import { MongoID, MongoObjectID, ErrorCode, TargetID } from '../types';
import { mongoIDSchema } from './kleen-schemas';
import { collection, toMongoObjectID, sameID } from '../db';
import { malformedFieldError } from '../util';


/**
 * The completed table represents the tidbits that every user has completed.
 */
export interface Completed {
  tidbitPointer: TidbitPointer;
  user: MongoID;

  _id?: MongoID;
}

/**
 * Converts all IDs to ObjectID format, that way we can search the db.
 */
const completedToDBSearchForm = (completed: Completed): Completed => {
  return {
    tidbitPointer: {
      tidbitType: completed.tidbitPointer.tidbitType,
      targetID: toMongoObjectID(completed.tidbitPointer.targetID)
    },
    user: toMongoObjectID(completed.user)
  }
};

/**
 * Schema for validating a `Completed` incoming from the frontend.
 */
const completedSchema: kleen.objectSchema = {
  objectProperties: {
    tidbitPointer: tidbitPointerSchema,
    user: mongoIDSchema(malformedFieldError("completed.user")),
  },
  typeFailureError: malformedFieldError("completed")
}

/**
 * Checks that:
 *  - `completed` from user input is valid.
 *  - `userMakingRequest` is same as `user` in `completed`.
 */
const validCompletedAndUserPermission = (completed: Completed, userMakingRequest: MongoID): Promise<void> => {
  return kleen.validModel(completedSchema)(completed)
  .then(() => {
    if(!sameID(userMakingRequest, completed.user)) {
      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "You do not have permission to do this, stick to your own tidbits!"
      });
    }
  });
}

/**
 * All the db helpers for the `Completed` table.
 */
export const completedDBActions = {

  /**
   * Marks a tidbit as completed for a user. Does validation and permission checks.
   *
   * Returns the ID of the completed document if successful.
   */
  addCompleted: (completed: Completed, userMakingRequest: MongoID): Promise<TargetID> => {
    return validCompletedAndUserPermission(completed, userMakingRequest)
    .then(() => {
      return collection("completed");
    })
    .then((completedCollection) => {
      return completedCollection.findOneAndUpdate(
        completedToDBSearchForm(completed),
        completedToDBSearchForm(completed),
        {
          upsert: true,
          returnOriginal: false
        }
      );
    })
    .then((findAndModifyResult) => {
      if(findAndModifyResult.value) {
        return Promise.resolve({ targetID: findAndModifyResult.value._id });
      }

      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "There was an internal error when marking tidbit as complete"
      });
    });
  },

  /**
   * Marks a tidbit as incomplete IF it was already marked as completed for that
   * user, otherwise no changes are made. Does validation and permission checks.
   *
   * Returns [A promise to] true if the db was modified otherwise returns false.
   */
  removeCompleted: (completed: Completed, userMakingRequest: MongoID): Promise<boolean> => {
    return validCompletedAndUserPermission(completed, userMakingRequest)
    .then(() => {
      return collection("completed");
    })
    .then((completedCollection) => {
      return completedCollection.findOneAndDelete(
        completedToDBSearchForm(completed)
      );
    })
    .then((deleteResult) => {
      if(deleteResult.value) {
        return true;
      }

      return false;
    });
  },

  /**
   * Returns [a promise to] true if the user has completed that tidbit. Does
   * validation and permission checks.
   */
  isCompleted: (completed: Completed, userMakingRequest: MongoID): Promise<boolean> => {
    return validCompletedAndUserPermission(completed, userMakingRequest)
    .then(() => {
      return collection("completed");
    })
    .then<Completed>((completedCollection) => {
      return completedCollection.findOne(
        completedToDBSearchForm(completed)
      );
    })
    .then((completed) => {
      if(completed) {
        return true;
      }

      return false;
    });
  }
}
