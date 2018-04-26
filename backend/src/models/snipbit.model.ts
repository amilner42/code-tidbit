/// Module for encapsulating helper functions for the Snipbit model.

import * as kleen from "kleen";
import moment from 'moment';
import R from "ramda";

import { opinionDBActions } from "./opinion.model";
import { malformedFieldError, isNullOrUndefined, dropNullAndUndefinedProperties } from '../util';
import { collection, renameIDField, toMongoObjectID } from '../db';
import { MongoID, MongoObjectID, ErrorCode, TargetID } from '../types';
import { ContentSearchFilter, ContentResultManipulation, ContentType, ContentPointer, getContent } from "./content.model";
import { Range, emptyRange } from './range.model';
import * as KS from './kleen-schemas';
import { qaDBActions } from "./qa.model";
import { TidbitType, updateCommentAbsoluteLinks } from "./tidbit.model";


/**
 * A Snipbit is one of the tidbits.
 */
export interface Snipbit {
  name: string;
  description: string;
  tags: string[];
  code: string;
  highlightedComments: SnipbitHighlightedComment[];

  // Added/modified by the backend.
  id?: MongoID; // When sending to the frontend, we switch `_id` to `id`.
  language: string;
  _id?: MongoID;
  author?: MongoID;
  authorEmail?: string;
  createdAt?: Date;
  lastModified?: Date;
  likes?: number;     // In the `opinions` collection, attached by the backend.
}

/**
 * A highlighted comment in a Snipbit.
 */
export interface SnipbitHighlightedComment {
  comment: string;
  range: Range;
}

/**
 * The search options.
 */
export interface SnipbitSearchFilter extends ContentSearchFilter { }

/**
 * The result manipulation options.
 */
export interface SnipbitResultManipulation extends ContentResultManipulation { }

/**
* Kleen schema for a HighlightComment.
*/
const snipbitHighlightedCommentSchema: kleen.objectSchema = {
  objectProperties: {
    "comment": KS.commentSchema(ErrorCode.snipbitEmptyComment),
    "range": KS.rangeSchema(ErrorCode.snipbitEmptyRange)
  }
};

/**
* Kleen schema for a Snipbit.
*/
const snipbitSchema: kleen.objectSchema = {
  objectProperties: {
    "language": KS.languageSchema(ErrorCode.snipbitInvalidLanguage),
    "name": KS.nameSchema(ErrorCode.snipbitEmptyName, ErrorCode.snipbitNameTooLong),
    "description": KS.descriptionSchema(ErrorCode.snipbitEmptyDescription, ErrorCode.snipbitDescriptionTooLong),
    "tags": KS.tagsSchema(ErrorCode.snipbitEmptyTag, ErrorCode.snipbitNoTags),
    "code": KS.codeSchema(ErrorCode.snipbitEmptyCode),
    "highlightedComments": KS.nonEmptyArraySchema(
      snipbitHighlightedCommentSchema,
      {
        errorCode: ErrorCode.snipbitNoHighlightedComments,
        message: "You must have at least one highlighted comment."
      },
      malformedFieldError("snipbit.highlightedComments")
    )
  },
  typeFailureError: malformedFieldError("snipbit")
};

/**
 * Prepares a snipbit for the frontend:
 *   - renaming the `_id` field
 *   - fetching and attaching ratings.
 */
const prepareSnipbitForResponse = (snipbit: Snipbit): Promise<Snipbit> => {
  const snipbitCopy = R.clone(snipbit);
  const contentPointer: ContentPointer = {
    contentID: snipbitCopy._id,
    contentType: ContentType.Snipbit
  };

  return opinionDBActions.getOpinionsCountOnContent(contentPointer, false)
  .then(({ likes }) => {
    snipbitCopy.likes = likes;

    return renameIDField(snipbitCopy);
  });
};

/**
 * All the db helpers for a snipbit.
 */
export const snipbitDBActions = {

  /**
   * Adds a new snipbit for a user, automatically attaches:
   *  - `author` (user ID)
   *  - `authorEmail`
   *  - `createdAt`
   *  - `lastModified`
   *
   * Will additionally initialize the QA for the given snipbit.
   *
   * Returns the ID of the newly created snipbit.
   */
  addNewSnipbit: (userID: MongoID, userEmail: string, snipbit: Snipbit, doValidation = true): Promise<TargetID> => {
    return (doValidation ? kleen.validModel(snipbitSchema)(snipbit) : Promise.resolve())
    .then(() => {
      const dateNow = moment.utc().toDate();
      const validSnipbit = R.clone(snipbit);

      validSnipbit.author = userID;
      validSnipbit.authorEmail = userEmail;
      validSnipbit.createdAt = dateNow;
      validSnipbit.lastModified = dateNow;

      updateCommentAbsoluteLinks(validSnipbit);

      return collection("snipbits")
      .then((snipbitCollection) => {
        return snipbitCollection.insertOne(validSnipbit);
      })
      // After inserting snipbit, we initialize the QA for that snipbit and return the ID of the new snipbit.
      .then((insertSnipbitResult) => {
        return qaDBActions.newBlankQAForTidbit(
          {
            targetID: insertSnipbitResult.insertedId,
            tidbitType: TidbitType.Snipbit
          },
          toMongoObjectID(userID),
          false
        )
        .then(R.always({ targetID: insertSnipbitResult.insertedId }));
      });
    });
  },

  /**
   * Gets snipbits, customizable through the `SnipbitSearchFilter` and `SnipbitResultManipulation`.
   */
  getSnipbits: (filter: SnipbitSearchFilter, resultManipulation: SnipbitResultManipulation): Promise<[boolean, Snipbit[]]> => {
    return getContent(ContentType.Snipbit, filter, resultManipulation, prepareSnipbitForResponse);
  },

  /**
   * Gets a snipbit from the database, handles all required transformations to
   * get the snipbit in the proper format for the frontend.
   */
  getSnipbit: (snipbitID: MongoID): Promise<Snipbit> => {
    return collection("snipbits")
    .then<Snipbit>((snipbitCollection) => {
      return snipbitCollection.findOne({ _id: toMongoObjectID(snipbitID)});
    })
    .then((snipbit) => {

      if(!snipbit) {
        return Promise.reject({
          errorCode: ErrorCode.snipbitDoesNotExist,
          message: `ID ${snipbitID} does not point to a snipbit.`
        });
      }

      return Promise.resolve(prepareSnipbitForResponse(snipbit));
    });
  },

  /**
   * Checks if a snipbit exists.
   */
  hasSnipbit: (snipbitID: MongoID): Promise<boolean> => {
    return collection("snipbits")
    .then((snipbitCollection) => {
      return snipbitCollection.count({ _id: toMongoObjectID(snipbitID)});
    })
    .then((numberOfSnipbitsWithID) => {
      return numberOfSnipbitsWithID > 0;
    });
  }
}
