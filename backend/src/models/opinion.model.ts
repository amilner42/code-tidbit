/// Module for encapsulating helper functions for the Opinion model.

import * as kleen from "kleen";
import { Collection } from "mongodb";

import { NotificationType, ContentOpinionCountData, notificationDBActions, makeNotification, isCountNotificationWorthy } from "./notification.model";
import { malformedFieldError, internalError } from "../util";
import { collection, toMongoObjectID, updateOneResultHandlers } from "../db";
import { MongoID, MongoObjectID  } from "../types";
import { ContentPointer, contentPointerToDBQueryForm, ContentType, contentPointerSchema, contentDBActions } from "./content.model";


/**
 * As seen in the `opinions` collection.
 */
export interface Opinion {
  contentPointer: ContentPointer,
  userID: MongoID,
  rating: Rating
}

/**
 * All the ratings for some content.
 */
export interface Ratings {
  likes: number
}

/**
 * All ways to rate content.
 *
 * Currently we only allow to "like" content.
 *
 * WARNING: Because of a bug with typescript enums, https://github.com/Microsoft/TypeScript/issues/12771, this enum
 *          does not properly type check everywhere. Be very careful when adding a new Rating.
 *            - When using this enum unsafely, add a link to the issue
 *            - If adding a value to the enum ctrl-f the link and manually find the type errors...
 */
export enum Rating {
  Like = 1
};

/**
 * The schema for a `Rating`.
 */
export const ratingSchema: kleen.primitiveSchema = {
  primitiveType: kleen.kindOfPrimitive.number,
  typeFailureError: malformedFieldError("rating"),
  restriction: (rating: Rating) => {
    if(!(rating in Rating)) return Promise.reject(malformedFieldError("rating"));
  }
};

/**
 * All the DB helpers for `opinion`s.
 */
export const opinionDBActions = {
  /**
   * Returns the # of each rating that the content has.
   *
   * NOTE: If the contentPointer doesn't point to existant content it will just return 0 for all `Rating`s.
   */
  getOpinionsCountOnContent: (contentPointer: ContentPointer, doValidation = true): Promise<Ratings> => {
    return (doValidation ? kleen.validModel(contentPointerSchema)(contentPointer) : Promise.resolve())
    .then(() => {
      return Promise.all([ opinionDBActions.getOpinionCountOnContent(contentPointer, Rating.Like, false) ]);
    })
    .then(([ likes ]) => {
      return { likes };
    });
  },

  /**
   * Returns the # of one specific rating that the content has.
   *
   * NOTE: If the contentPointer doesn't point to existant content, it will just return 0.
   */
  getOpinionCountOnContent: (contentPointer: ContentPointer, rating: Rating, doValidation = true): Promise<number> => {
    const validation = () => {
      return Promise.all([
        kleen.validModel(contentPointerSchema)(contentPointer),
        kleen.validModel(ratingSchema)(rating)
      ]);
    };

    return (doValidation ? validation() : Promise.resolve([]))
    .then(() => {
      return collection("opinions");
    })
    .then((opinionCollection) => {
      return opinionCollection.count({
        contentPointer: contentPointerToDBQueryForm(contentPointer),
        rating
      });
    });
  },

  /**
   * For getting a users opinion on some content.
   *
   * NOTE: Returns `null` if the `user` has no opinion yet or if the `contentPointer`/`user` don't exist.
   */
  getUsersOpinionOnContent: (contentPointer: ContentPointer, userID: MongoObjectID, doValidation = true): Promise<Rating> => {
    return (doValidation ? kleen.validModel(contentPointerSchema)(contentPointer) : Promise.resolve())
    .then(() => {
      return collection("opinions");
    })
    .then((opinions) => {
      return opinions.findOne({
        userID,
        contentPointer: contentPointerToDBQueryForm(contentPointer)
      });
    })
    .then((opinion: Opinion) => {
      if(!opinion) {
        return null;
      }

      return opinion.rating;
    });
  },

  /**
   * Adds an opinion, returns true if an upsert was performed.
   *
   * NOTE: will overwrite the previous opinion if one existed.
   */
  addOpinion: (contentPointer: ContentPointer, rating: Rating, userID: MongoObjectID, doValidation = true): Promise<boolean> => {
    const validation = () => {
      return Promise.all([
        kleen.validModel(contentPointerSchema)(contentPointer),
        kleen.validModel(ratingSchema)(rating)
      ]);
    };

    // To avoid re-querying the db if we want to send a notiication, we capture the contentName in an earier db query.
    let contentName: string;
    let contentAuthorID: MongoID;

    return (doValidation ? validation() : Promise.resolve([]))
    .then(() => {
      return contentDBActions.expandContentPointer(contentPointer, false);
    })
    .then<Collection>((content) => {
      if(content === null) {
        return Promise.reject(internalError("Pointing to non-existant content"));
      }

      contentName = content.name;
      contentAuthorID = content.author;
      return collection("opinions");
    })
    .then((opinions) => {
      const contentPointerInDBForm = contentPointerToDBQueryForm(contentPointer);
      const opinion: Opinion = { contentPointer: contentPointerInDBForm, rating, userID };

      return opinions.updateOne(
        {
          contentPointer: contentPointerInDBForm,
          userID
        },
        opinion,
        {
          upsert: true
        }
      );
    })
    .then(updateOneResultHandlers.rejectIfResultNotOK)
    .then((updateResult) => {
      // Create a notification if needed.
      {
        const createOpinionNotification = () => {
          if(updateResult.upsertedCount === 1) {
            return opinionDBActions.getOpinionCountOnContent(contentPointer, rating, false)
            .then((opinionCount) => {
              if(isCountNotificationWorthy(opinionCount)) {
                const notificationData: ContentOpinionCountData = {
                  type: NotificationType.ContentOpinionCount,
                  count: opinionCount,
                  rating,
                  contentPointer,
                  contentName
                };

                return makeNotification(notificationData)(contentAuthorID);
              }
            });
          }

          return Promise.resolve(null);
        };

        notificationDBActions.addNotificationWrapper(createOpinionNotification);
      }

      if(updateResult.upsertedCount === 1) {
        return true;
      }
      return false;
    });
  },

  /**
   * Removes an opinion, opposite to `addOpinion`. Will return true if the opinion existed and was deleted, otherwise
   * if it didn't exist to begin with will return false.
   */
  removeOpinion: (contentPointer: ContentPointer, rating: Rating, userID: MongoObjectID, doValidation = true): Promise<boolean> => {
    const validation = () => {
      return Promise.all([
        kleen.validModel(contentPointerSchema)(contentPointer),
        kleen.validModel(ratingSchema)(rating)
      ]);
    };

    return (doValidation ? validation() : Promise.resolve([]))
    .then(() => {
      return collection("opinions");
    })
    .then((opinions) => {
      const contentPointerInDBForm: ContentPointer = contentPointerToDBQueryForm(contentPointer);
      const opinion: Opinion = { contentPointer: contentPointerInDBForm, rating, userID };

      return opinions.deleteOne(opinion);
    })
    .then((deleteResult) => {
      return deleteResult.deletedCount === 1;
    });
  }
}
