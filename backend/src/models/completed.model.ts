/// Module for encapsulating helper functions for the completed model.

import * as kleen from "kleen";

import { TidbitPointer, tidbitPointerSchema } from "./tidbit.model";
import { MongoID, ErrorCode } from '../types';
import { mongoIDSchema } from './kleen-schemas';
import { collection, ID, sameID } from '../db';
import { malformedFieldError } from '../util';


/**
 * The completed table represents the the tidbits that every user has completed.
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
      targetID: ID(completed.tidbitPointer.targetID)
    },
    user: ID(completed.user)
  }
};

/**
 * Schema for validating a `Completed` incoming from the frontend.
 */
const completedSchema: kleen.typeSchema = {
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

    return;
  });
}

/**
 * All the db helpers for the `Completed` table.
 */
export const completedDBActions = {

  /**
   * Marks a tidbit as completed for a user.
   *
   * NOTE: Method is safe, running validation against `completed` and permission
   *       checks to make sure the `userMakingRequest` is the one in `completed`.
   */
  markAsComplete: (completed: Completed, userMakingRequest: MongoID): Promise<{ targetID: MongoID }> => {
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
    .then((upatedCompletedResult) => {
      const updatedCompleted: Completed = upatedCompletedResult.value;
      if(updatedCompleted) {
        return { targetID: updatedCompleted._id }
      }

      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "There was an internal error when marking tidbit as complete"
      });
    });
  },

  /**
   * Marks a tidbit as incomplete IF it was already marked as completed for that
   * user, otherwise no changes are made.
   *
   * Returns [A promise to] true if the db was modified otherwise returns false.
   *
   * NOTE: Method is safe, running validation against `completed` and permission
   *       checks to make sure the `userMakingRequest` is the one in `completed`.
   */
  markAsIncomplete: (completed: Completed, userMakingRequest: MongoID): Promise<boolean> => {
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
   * Returns [a promise to] true if the user has completed that tidbit.
   *
   * NOTE: Method is safe, running validation against `completed` and permission
   *       checks to make sure the `userMakingRequest` is the one in `completed`.
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
