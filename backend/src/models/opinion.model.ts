/// Module for encapsulating helper functions for the Opinion model.

import * as kleen from "kleen";

import { mongoStringIDSchema } from "./kleen-schemas";
import { malformedFieldError } from "../util";
import { collection, toMongoObjectID } from "../db";
import { MongoID, MongoObjectID  } from "../types";
import { ContentPointer, contentPointerToDBQueryForm, ContentType, contentPointerSchema } from "./content.model";


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
  dislikes: number,
  likes: number
}

/**
 * You can either like or dislike content.
 */
export enum Rating {
  Dislike = -1,
  Like = 1
};

/**
 * The schema for a `Rating`.
 */
export const ratingSchema = {
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
   * Returns dislikes/likes for specific content.
   *
   * NOTE: If the contentPointer doesn't point to existant content it will just return 0 likes/dislikes.
   */
  getAllOpinionsOnContent: (contentPointer: ContentPointer): Promise<Ratings> => {
    return kleen.validModel(contentPointerSchema)(contentPointer)
    .then(() => {
      return collection("opinions");
    })
    .then((opinions) => {
      // Count how many ratings the content (`contentPointer`) has for a specific rating.
      const countWithRating = (rating: Rating): PromiseLike<number> => {
        return opinions.find({
          contentPointer: contentPointerToDBQueryForm(contentPointer),
          rating
        }).count(false);
      }

      return Promise.all([ countWithRating(Rating.Dislike), countWithRating(Rating.Like) ]);
    })
    .then(([dislikes, likes]) => {
      return { dislikes, likes };
    });
  },

  /**
   * For checking if a user has already liked/disliked content.
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
  }
}
