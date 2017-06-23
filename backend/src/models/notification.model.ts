/// Module for encapsulating helper functions for the notification model.

import * as kleen from "kleen";
import moment from "moment";

import { mongoIDSchema } from "./kleen-schemas";
import { MongoObjectID, MongoID } from "../types";
import { malformedFieldError, internalError } from "../util";
import { toMongoObjectID, collection, getPaginatedResults, renameIDField } from "../db";


/**
 *  The types of notifications
 */
export enum NotificationType {
  CompletedCount = 1,
  LikesCount,
  Pinned,
  NewQuestion,
  NewAnswer,
  NewComment
};

/**
 *  A notification as seen in the database.
 */
export interface Notification {
  _id?: MongoObjectID;
  userID: MongoObjectID;
  type: NotificationType;
  message: String;
  actionLink?: String;
  read: boolean;
  createdAt: Date;
};

/**
 * Prepares the notification for the frontend:
 *  - renames the ID field
 */
export const prepareNotificationForResponse = (notification: Notification): Notification => {
  return renameIDField(notification);
};

/**
 * All the db helpers for handling `Notification` related tasks.
 */
export const notificationDBActions = {
  /**
   * Create a new notification.
   *
   * NOTE: This will not push it to the user, it will just add the notification to the db.
   *
   * NOTE: We don't do validation here because this is only intended to be called from within the app itself.
   */
  addNotification: (userID: MongoID, type: NotificationType, message: String, actionLink?: String): Promise<void> => {
    const dateNow = moment.utc().toDate();

    const newNotification: Notification = {
      userID: toMongoObjectID(userID),
      type,
      message,
      actionLink,
      read: false,
      createdAt: dateNow
    };

    return collection("notifications")
    .then((notificationCollection) => {
      return notificationCollection.insertOne(newNotification);
    })
    .then((insertResult) => {
      if(insertResult.insertedCount === 1) {
        return;
      }

      return Promise.reject(internalError("Failed to add notification"));
    })
  },

  /**
   * Set's the boolean state of `read` for a given notification.
   *
   * PERMISSIONS: `userMakingRequest` must be === `userID`
   */
  setRead: (userMakingRequest: MongoID, notificationID: MongoID, read: boolean, doValidation = true): Promise<void> => {
    const validation = () => kleen.validModel(mongoIDSchema(malformedFieldError("notificationID")))(notificationID);

    return (doValidation ? validation() : Promise.resolve())
    .then(() => {
      return collection("notifications");
    })
    .then((notificationCollection) => {
      return notificationCollection.updateOne(
        { _id: toMongoObjectID(notificationID)
        , userID: toMongoObjectID(userMakingRequest)
        },
        { $set: { read } },
        { upsert: false }
      );
    })
    .then((updateResult) => {
      if(updateResult.modifiedCount === 1) {
        return;
      }

      return Promise.reject(internalError("Failed to set read."));
    });
  },

  /**
   * Get's (paginated) notifications for a user.
   *
   * @NOTE The `userID` should be generated by the backend from the request, users should not be able to request other
   *       users' notifications.
   *
   * @RETURNS [ boolean specifying whether there are more notifications, notifications for that page ]
   */
  getNotifications: (userID: MongoID, pageNumber = 1, pageSize = 100): Promise<[ boolean, Notification[] ]> => {
    return collection("notifications")
    .then((notificationCollection) => {
      const cursor = notificationCollection.find({ userID: toMongoObjectID(userID) }).sort({ createdAt: -1 });

      return getPaginatedResults(pageNumber, pageSize, cursor);
    })
    .then(([ isMoreResults, results ]) => {
      return [ isMoreResults, results.map(prepareNotificationForResponse) ]
    });
  }
}
