/// Module for encapsulating helper functions for the Opinion model.

import * as kleen from "kleen";
import { Collection } from "mongodb";

import { mongoStringIDSchema } from "./kleen-schemas";
import { malformedFieldError, internalError } from "../util";
import { collection, toMongoObjectID } from "../db";
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
   * Returns `Rating`s for specific content.
   *
   * NOTE: If the contentPointer doesn't point to existant content it will just return 0 for all `Rating`s.
   */
  getAllOpinionsOnContent: (contentPointer: ContentPointer): Promise<Ratings> => {
    return kleen.validModel(contentPointerSchema)(contentPointer)
    .then(() => {
      return collection("opinions");
    })
    .then((opinions) => {
      // Count how many ratings the content (`contentPointer`) has for a specific `Rating`.
      const countWithRating = (rating: Rating): PromiseLike<number> => {
        return opinions.find({
          contentPointer: contentPointerToDBQueryForm(contentPointer),
          rating
        }).count(false);
      }

      return Promise.all([ countWithRating(Rating.Like) ]);
    })
    .then(([ likes ]) => {
      return { likes };
    });
  },

  /**
   * For getting a users opinion on some content.
   *
   * NOTE: Returns `null` if the `user` has no opinion yet or if the `contentPointer`/`user` don't exist.
   */
  getUsersOpinionOnContent: (contentPointer: ContentPointer, userID: MongoObjectID): Promise<Rating> => {
    return kleen.validModel(contentPointerSchema)(contentPointer)
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
   */
  addOpinion: (contentPointer: ContentPointer, rating: Rating, userID: MongoObjectID): Promise<boolean> => {
    return Promise.all([
      kleen.validModel(contentPointerSchema)(contentPointer),
      kleen.validModel(ratingSchema)(rating)
    ])
    .then(() => {
      return contentDBActions.contentPointerExists(contentPointer);
    })
    .then<Collection>((contentExists) => {
      if(!contentExists) {
        return Promise.reject(internalError("Pointing to non-existant content"));
      }

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
    .then((updateResult) => {
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
  removeOpinion: (contentPointer: ContentPointer, rating: Rating, userID: MongoObjectID): Promise<boolean> => {
    return Promise.all([
      kleen.validModel(contentPointerSchema)(contentPointer),
      kleen.validModel(ratingSchema)(rating)
    ])
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
