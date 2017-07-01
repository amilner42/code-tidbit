/// Module for encapsulating helper functions for the notification model.

import * as kleen from "kleen";
import moment from "moment";
import * as R from "ramda";

import { Rating } from "./opinion.model";
import { ContentPointer, ContentType } from "./content.model";
import { TidbitPointer, TidbitType, toContentType, toContentPointer } from "./tidbit.model";
import { mongoIDSchema } from "./kleen-schemas";
import { MongoObjectID, MongoID } from "../types";
import { malformedFieldError, internalError, assertNever, isNullOrUndefined, createRegenerativePromise } from "../util";
import { toMongoObjectID, toMongoStringID, collection, getPaginatedResults, renameIDField, updateOneResultHandlers } from "../db";


/**
 * A notification as seen in the database.
 *
 * NOTE: Avoid creating these manually, use `createNotification`, it will handle creating the notification given the
 *       `NotificationData`.
 *
 * NOTE: The point of `hash` is to be able to quickly check the database if a notification has already been made. For
 *       example, a user may hit 100 likes, we send out the notification, and then someone removes a like and someone
 *       else likes it again, so we've once again hit 100 likes. To check the db quickly if we've already created
 *       that notification we check the hash. We don't use the `message` as a hash because we may change the messages
 *       frequently, which would ruin all previous hashes.
 */
export interface Notification {
  _id?: MongoObjectID;
  userID: MongoObjectID;
  type: NotificationType;
  message: String;
  actionLink?: [ LinkName, Link ];
  read: boolean;
  createdAt: Date;
  hash: string;
};

/**
 *  The types of notifications
 *
 * NOTE: If you add new notifications, you HAVE to add them at the bottom of the enum, the reason being you do not want
 *       to change the int of any existing values in the enum.
 */
export enum NotificationType {
  TidbitCompletedCount = 1,
  ContentOpinionCount,
  TidbitQuestionLikeCount,
  TidbitAnswerLikeCount,
  TidbitQuestionPinned,
  TidbitAnswerPinned,
  TidbitNewQuestion,
  TidbitNewAnswer,
  TidbitNewQuestionComment,
  TidbitNewAnswerComment
};

/**
 * The data required to create a notification.
 *
 * NOTE This should be treated as a tagged union where `type` is the tag.
 */
export type NotificationData
  = TidbitCompletedCountData
  | ContentOpinionCountData
  | TidbitQuestionLikeCountData
  | TidbitAnswerLikeCountData
  | TidbitQuestionPinnedData
  | TidbitAnswerPinnedData
  | TidbitNewQuestionData
  | TidbitNewAnswerData
  | TidbitNewQuestionCommentData
  | TidbitNewAnswerCommentData

/**
 * The data required to create a `TidbitCompletedCount` notification.
 */
export interface TidbitCompletedCountData {
  type: NotificationType.TidbitCompletedCount;
  count: number;
  tidbitPointer: TidbitPointer;
  tidbitName: string;
};

/**
 * The data required to create a `ContentOpinionCount` notification.
 */
export interface ContentOpinionCountData {
  type: NotificationType.ContentOpinionCount;
  count: number;
  rating: Rating;
  contentPointer: ContentPointer;
  contentName: string;
};

/**
 * The data required to create a `TidbitQuestionLikeCount` notification.
 */
export interface TidbitQuestionLikeCountData {
  type: NotificationType.TidbitQuestionLikeCount;
  count: number;
  tidbitPointer: TidbitPointer;
  questionID: MongoID;
  tidbitName: string;
};

/**
 * The data required to create a `TidbitAnswerLikeCount` notification.
 */
export interface TidbitAnswerLikeCountData {
  type: NotificationType.TidbitAnswerLikeCount;
  count: number;
  tidbitPointer: TidbitPointer;
  answerID: MongoID;
  tidbitName: string;
};

/**
 * The data required to create a `TidbitQuestionPinned` notification.
 */
export interface TidbitQuestionPinnedData {
  type: NotificationType.TidbitQuestionPinned;
  tidbitPointer: TidbitPointer;
  questionID: MongoID;
  tidbitName: string;
};

/**
 * The data required to create a `TidbitAnswerPinned` notification.
 */
export interface TidbitAnswerPinnedData {
  type: NotificationType.TidbitAnswerPinned;
  tidbitPointer: TidbitPointer;
  answerID: MongoID;
  tidbitName: string;
};

/**
 * The data required to create a `TidbitNewQuestion` notification.
 */
export interface TidbitNewQuestionData {
  type: NotificationType.TidbitNewQuestion;
  tidbitPointer: TidbitPointer;
  questionID: MongoID;
  tidbitName: string;
  isTidbitAuthor: (userID: MongoID) => boolean;
};

/**
 * The data required to create a `TidbitNewAnswer` notification.
 */
export interface TidbitNewAnswerData {
  type: NotificationType.TidbitNewAnswer;
  tidbitPointer: TidbitPointer;
  answerID: MongoID;
  tidbitName: string;
  isQuestionAuthor: (userID: MongoID) => boolean;
  isTidbitAuthor: (userID: MongoID) => boolean;
};

/**
 * The data required to create a `TidbitNewQuestionComment`.
 */
export interface TidbitNewQuestionCommentData {
  type: NotificationType.TidbitNewQuestionComment;
  tidbitPointer: TidbitPointer;
  questionID: MongoID;
  commentID: MongoID;
  tidbitName: string;
};

/**
 * The data required to create a `TidbitNewAnswerComment`.
 */
export interface TidbitNewAnswerCommentData {
  type: NotificationType.TidbitNewAnswerComment;
  tidbitPointer: TidbitPointer;
  answerID: MongoID;
  commentID: MongoID;
  tidbitName: string;
};

// Type-aliases for clarity.
type Link = string;
type LinkName = string;

/**
 * Returns true if the count should trigger a notification (the count could be for completions, likes, etc...).
 */
export const isCountNotificationWorthy = (count: number): boolean => {
  if(count <= 1000) {
    return R.contains(count, [ 5, 10, 25, 50, 75, 100, 200, 300, 400, 500, 750, 1000 ]);
  }

  return count % 1000 === 0;
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
   *
   * RETURNS: The number of upserted documents (will be either 1 or 0).
   */
  addNotification: (notification: Notification): Promise<number> => {

    return collection("notifications")
    .then((notificationCollection) => {
      return notificationCollection.updateOne(
        { hash: notification.hash },
        { $setOnInsert: notification },
        { upsert: true }
      );
    })
    .then(updateOneResultHandlers.rejectIfResultNotOK)
    .then((updateResult) => {
      return updateResult.upsertedCount;
    });
  },

  /**
   * Use this to wrap your promise which creates the notification. This will handle adding the notification to the DB,
   * logging notification errors and also retrying to create the notification a couple times if it fails the first time.
   *
   * NOTE: If `createNotification` returns `null`/`undefined` instead of a `Notification`, then no notification will be
   *       created. You can use this if your `createNotification` is conditional.
   */
  addNotificationWrapper: (createNotification: () => Promise<Notification | Notification[]>): void => {

    const createNotificationRegenerative = createRegenerativePromise(
      createNotification,
      3,
      (errors) => {
        console.log("Failed to create notification, here are the errors for each attempt: ", errors);
      },
      R.always(null)
    );

    const addNotificationRegenerative = (notification: Notification): Promise<number> => {
      return createRegenerativePromise(
        () => { return notificationDBActions.addNotification(notification); },
        3,
        (errors) => {
          console.log("Failed to add notification, here are the errors for each attempt: ", errors);
        },
        R.always(null)
      )();
    };

    createNotificationRegenerative()
    .then((notification) => {
      if(isNullOrUndefined(notification)) return null;

      if(Array.isArray(notification)) {
        notification.map(addNotificationRegenerative);
      } else {
        addNotificationRegenerative(notification);
      }
    });
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
    .then(updateOneResultHandlers.rejectIfResultNotOK)
    .then(updateOneResultHandlers.rejectIfNoneModified)
    .then(R.always(null));
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

      return getPaginatedResults(pageNumber, Math.min(100, pageSize), cursor);
    })
    .then(([ isMoreResults, results ]) => {
      return [ isMoreResults, results.map(prepareNotificationForResponse) ]
    });
  }
};

/**
 * Creates a notification from the given `NotificationData`. Will handle all fields including `actionLink` (if required)
 * and `hash`.
 */
export const makeNotification = (nd: NotificationData): ((userID: MongoID) => Notification) => {

  return (userID): Notification => {
    userID = toMongoObjectID(userID);
    const createdAt = moment.utc().toDate();
    const type = nd.type;
    const read = false;

    // Use for making the hash, this will alredy include `userID` and `type` in the hash.
    // Do not modify (or if you do, make sure it doesn't break old hashes in the db).
    const makeHash = (strArray: string[]): string => {
      return strArray.concat([ toMongoStringID(userID), type.toString() ]).join(":");
    };

    // Output looks like: snipbit "How to create decoders in Elm"
    const contentNameInString = (contentType: ContentType, contentName: string): string => {
      return `${contentTypeToName(contentType)} "${contentName}"`;
    };

    const tidbitNameInString = (tidbitType: TidbitType, tidbitName: string): string => {
      return contentNameInString(toContentType(tidbitType), tidbitName);
    };

    switch(nd.type) {
      case NotificationType.TidbitCompletedCount: {
        const tidbitTypeName = contentTypeToName(toContentType(nd.tidbitPointer.tidbitType));
        const hash = makeHash([ toMongoStringID(nd.tidbitPointer.targetID), nd.count.toString() ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `Your ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)} has been completed by ${nd.count} people!`,
          actionLink: [
            "view",
            getContentLink(toContentPointer(nd.tidbitPointer))
          ],
          hash
        };
      }

      case NotificationType.ContentOpinionCount: {
        const hash =
          makeHash([ toMongoStringID(nd.contentPointer.contentID), nd.rating.toString(), nd.count.toString() ]);

        const opinionRatingToHumanReadablePluralName = (rating: Rating): string => {
          switch(rating) {
            case Rating.Like:
              return "likes";

            // Casting because of ts bug: https://github.com/Microsoft/TypeScript/issues/12771.
            default: assertNever(rating as never);
          }
        };

        return {
          userID,
          type,
          createdAt,
          read,
          message: `Your ${contentNameInString(nd.contentPointer.contentType, nd.contentName)} just hit ${nd.count} ${opinionRatingToHumanReadablePluralName(nd.rating)}!`,
          actionLink: [
            "view",
            getContentLink(nd.contentPointer)
          ],
          hash
        };
      }

      case NotificationType.TidbitQuestionLikeCount: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.questionID),
          nd.count.toString()
        ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `Your question on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)} just hit ${nd.count} likes!`,
          actionLink: [
            "view",
            getQuestionLink(nd.tidbitPointer, nd.questionID)
          ],
          hash
        };
      }

      case NotificationType.TidbitAnswerLikeCount: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.answerID),
          nd.count.toString()
        ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `Your answer on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)} just hit ${nd.count} likes!`,
          actionLink: [
            "view",
            getAnswerLink(nd.tidbitPointer, nd.answerID)
          ],
          hash
        };
      }

      case NotificationType.TidbitQuestionPinned: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.questionID)
        ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `Your question on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)} just got pinned!`,
          actionLink: [
            "view",
            getQuestionLink(nd.tidbitPointer, nd.questionID)
          ],
          hash
        };
      }

      case NotificationType.TidbitAnswerPinned: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.answerID)
        ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `Your answer on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)} just got pinned!`,
          actionLink: [
            "view",
            getAnswerLink(nd.tidbitPointer, nd.answerID)
          ],
          hash
        };
      }

      case NotificationType.TidbitNewQuestion: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.questionID)
        ]);

        const authorMessage =
          `A new question was posted on your ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}`;

        const subscribedUserMessage =
          `A new question was posted on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}`;

        return {
          userID,
          type,
          createdAt,
          read,
          message: nd.isTidbitAuthor(userID) ? authorMessage : subscribedUserMessage,
          actionLink: [
            "view",
            getQuestionLink(nd.tidbitPointer, nd.questionID)
          ],
          hash
        };
      }

      case NotificationType.TidbitNewAnswer: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.answerID)
        ]);

        const message = (() => {
          const questionAuthorMessage
            = `Someone answered your question on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}!`;

          const tidbitAuthorMessage
            = `A new answer was posted on your ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}`

          const subscribedUserMessage
            = `A new answer was posted on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}`;

          if(nd.isQuestionAuthor(userID)) return questionAuthorMessage;
          if(nd.isTidbitAuthor(userID)) return tidbitAuthorMessage;

          return subscribedUserMessage;
        })();

        return {
          userID,
          type,
          createdAt,
          read,
          message,
          actionLink: [
            "view",
            getAnswerLink(nd.tidbitPointer, nd.answerID)
          ],
          hash
        };
      }

      case NotificationType.TidbitNewQuestionComment: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.questionID),
          toMongoStringID(nd.commentID)
        ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `A thread you are in has a new comment on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}`,
          actionLink: [
            "view",
            getQuestionCommentsLink(nd.tidbitPointer, nd.questionID)
          ],
          hash
        };
      }

      case NotificationType.TidbitNewAnswerComment: {
        const hash = makeHash([
          toMongoStringID(nd.tidbitPointer.targetID),
          toMongoStringID(nd.answerID),
          toMongoStringID(nd.commentID)
        ]);

        return {
          userID,
          type,
          createdAt,
          read,
          message: `A thread you are in has a new comment on ${tidbitNameInString(nd.tidbitPointer.tidbitType, nd.tidbitName)}`,
          actionLink: [
            "view",
            getAnswerCommentsLink(nd.tidbitPointer, nd.answerID)
          ],
          hash
        };
      }

      default:
        assertNever(nd);
    }
  }
};

/**
 * Gets the human-readable name for the given `ContentType`.
 */
const contentTypeToName = (contentType: ContentType): string => {
  switch(contentType) {
    case ContentType.Snipbit:
      return "snipbit";

    case ContentType.Bigbit:
      return "bigbit";

    case ContentType.Story:
      return "story";

    default:
      assertNever(contentType);
  }
};

const viewSnipbitBaseUrl = (snipbitID: MongoID): string => {
  return `#/view/snipbit/${snipbitID}`;
};

const viewBigbitBaseUrl = (bigbitID: MongoID): string => {
  return `#/view/bigbit/${bigbitID}`;
};

const viewStoryBaseUrl = (storyID: MongoID): string => {
  return `#/view/story/${storyID}`;
};

const tidbitBaseUrl = (tidbitPointer: TidbitPointer) => {
  switch(tidbitPointer.tidbitType) {
    case TidbitType.Snipbit:
      return viewSnipbitBaseUrl(tidbitPointer.targetID);

    case TidbitType.Bigbit:
      return viewBigbitBaseUrl(tidbitPointer.targetID);

    default: assertNever(tidbitPointer.tidbitType);
  }
};

/**
 * Get's the [relative] link to view some content.
 *
 * For tidbits this will link to the introduction.
 */
const getContentLink = (contentPointer: ContentPointer): Link => {
  switch(contentPointer.contentType) {
    case ContentType.Snipbit:
      return `${viewSnipbitBaseUrl(contentPointer.contentID)}/introduction`;

    case ContentType.Bigbit:
      return `${viewBigbitBaseUrl(contentPointer.contentID)}/introduction`;

    case ContentType.Story:
      return viewStoryBaseUrl(contentPointer.contentID);

    default: assertNever(contentPointer.contentType);
  }
};

/**
 * Get's the link to a question [on a tidbit].
 */
const getQuestionLink = (tidbitPointer: TidbitPointer, questionID: MongoID): Link => {
  return `${tidbitBaseUrl(tidbitPointer)}/question/${questionID}`
};

/**
 * Get's the link to an answer [on a tidbit].
 */
const getAnswerLink = (tidbitPointer: TidbitPointer, answerID: MongoID): Link => {
  return `${tidbitBaseUrl(tidbitPointer)}/answer/${answerID}`;
};

/**
 * Get's the link to the comments section [on a question on a tidbit].
 */
const getQuestionCommentsLink = (tidbitPointer: TidbitPointer, questionID: MongoID): Link => {
  return `${tidbitBaseUrl(tidbitPointer)}/question/${questionID}/comments`;
};

/**
 * Get's the link to the comments section [on an answer on a tidbit].
 */
const getAnswerCommentsLink = (tidbitPointer: TidbitPointer, answerID: MongoID): Link => {
  return `${tidbitBaseUrl(tidbitPointer)}/answer/${answerID}/comments`;
};
