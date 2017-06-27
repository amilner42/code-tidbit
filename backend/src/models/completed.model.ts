/// Module for encapsulating helper functions for the completed model.

import * as kleen from "kleen";

import { TidbitCompletedCountData, NotificationType, notificationDBActions, isCountNotificationWorthy, makeNotification } from "./notification.model";
import { TidbitPointer, tidbitPointerSchema, tidbitDBActions } from "./tidbit.model";
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
const validCompletedAndUserPermission =
  ( completed: Completed
  , userMakingRequest: MongoID
  , doValidation: boolean
  ): Promise<void> => {

  return (doValidation ? kleen.validModel(completedSchema)(completed) : Promise.resolve())
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
   * Returns `true` if the completed was upserted, and `false` if it was already in the db.
   */
  addCompleted: (completed: Completed, userMakingRequest: MongoID, doValidation = true): Promise<boolean> => {
    return validCompletedAndUserPermission(completed, userMakingRequest, doValidation)
    .then(() => {
      return collection("completed");
    })
    .then((completedCollection) => {
      return completedCollection.updateOne(
        completedToDBSearchForm(completed),
        completedToDBSearchForm(completed),
        { upsert: true }
      );
    })
    .then((updateResult) => {
      // Create a notification if needed.
      {
        const createCompletedNotification = () => {
          if(updateResult.upsertedCount === 1) {
            return Promise.all([
              completedDBActions.countCompleted(completed.tidbitPointer, false),
              tidbitDBActions.expandTidbitPointer(completed.tidbitPointer)
            ])
            .then(([ completedCount, tidbit ]) => {
              if(isCountNotificationWorthy(completedCount)) {
                const notificationData: TidbitCompletedCountData = {
                  type: NotificationType.TidbitCompletedCount,
                  count: completedCount,
                  tidbitName: tidbit.name,
                  tidbitPointer: completed.tidbitPointer
                }

                return makeNotification(notificationData)(tidbit.author);
              }
            });
          }

          return Promise.resolve(null);
        };

        notificationDBActions.addNotificationWrapper(createCompletedNotification);
      }

      return updateResult.upsertedCount === 1;
    });
  },

  /**
   * Marks a tidbit as incomplete IF it was already marked as completed for that
   * user, otherwise no changes are made. Does validation and permission checks.
   *
   * Returns [A promise to] true if the db was modified otherwise returns false.
   */
  removeCompleted: (completed: Completed, userMakingRequest: MongoID, doValidation = true): Promise<boolean> => {
    return validCompletedAndUserPermission(completed, userMakingRequest, doValidation)
    .then(() => {
      return collection("completed");
    })
    .then((completedCollection) => {
      return completedCollection.deleteOne(
        completedToDBSearchForm(completed)
      );
    })
    .then((deleteResult) => {
      return deleteResult.deletedCount === 1;
    });
  },

  /**
   * Returns [a promise to] true if the user has completed that tidbit. Does
   * validation and permission checks.
   */
  isCompleted: (completed: Completed, userMakingRequest: MongoID, doValidation = true): Promise<boolean> => {
    return validCompletedAndUserPermission(completed, userMakingRequest, doValidation)
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
  },

  /**
   * Counts the number of completions for a given tidbit.
   *
   * TODO May need to rethink indexing, which is currently compound on [user,tidbitPointer] which means it won't work
   *      for this query (we don't specify user). Perhaps compound on [tidbitPointer, user] would be better.
   */
  countCompleted: (tidbitPointer: TidbitPointer, doValidation = true): Promise<number> => {
    return (doValidation ? kleen.validModel(tidbitPointerSchema)(tidbitPointer) : Promise.resolve())
    .then(() => {
      return collection("completed");
    })
    .then((completedCollection) => {
      return completedCollection.count({
        tidbitPointer: {
          tidbitType: tidbitPointer.tidbitType,
          targetID: toMongoObjectID(tidbitPointer.targetID)
        }
      });
    });
  }
}
