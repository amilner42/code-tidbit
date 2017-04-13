/// Module for encapsulating helper functions for the Snipbit model.

import * as kleen from "kleen";
import moment from 'moment';

import { malformedFieldError, isNullOrUndefined, dropNullAndUndefinedProperties } from '../util';
import { collection, renameIDField, toMongoObjectID, paginateResults } from '../db';
import { MongoID, MongoObjectID, ErrorCode, TargetID } from '../types';
import { ContentSearchFilter, ContentResultManipulation, ContentType, getContent } from "./content.model";
import { Range, emptyRange } from './range.model';
import * as KS from './kleen-schemas';


/**
 * A Snipbit is one of the tidbits.
 */
export interface Snipbit {
  name: string;
  description: string;
  tags: string[];
  code: string;
  introduction: string;
  conclusion: string;
  highlightedComments: SnipbitHighlightedComment[];

  // Added/modified by the backend.
  id?: MongoID; // When sending to the frontend, we switch `_id` to `id`.
  language: string;
  _id?: MongoID;
  author?: MongoID;
  createdAt?: Date;
  lastModified?: Date;
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
    "introduction": KS.introductionSchema(ErrorCode.snipbitEmptyIntroduction),
    "conclusion": KS.conclusionSchema(ErrorCode.snipbitEmptyConclusion),
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
 *
 * @WARNING Mutates `snipbit`.
 */
const prepareSnipbitForResponse = (snipbit: Snipbit): Snipbit => {
  renameIDField(snipbit);
  return snipbit;
};

/**
 * All the db helpers for a snipbit.
 */
export const snipbitDBActions = {

  /**
   * Adds a new snipbit for a user, automatically attaches user as `author`, also adds `createdAt` and `lastModified`.
   */
  addNewSnipbit: (userID: MongoID, snipbit: Snipbit): Promise<TargetID> => {
    return kleen.validModel(snipbitSchema)(snipbit)
    .then(() => {
      const dateNow = moment.utc().toDate();

      snipbit.author = userID;
      snipbit.createdAt = dateNow;
      snipbit.lastModified = dateNow;

      return collection("snipbits")
      .then((snipbitCollection) => {
        return snipbitCollection.insertOne(snipbit);
      })
      .then((insertSnipbitResult) => {
        return { targetID: insertSnipbitResult.insertedId };
      });
    });
  },

  /**
   * Gets snipbits, customizable through the `SnipbitSearchFilter` and `SnipbitResultManipulation`.
   */
  getSnipbits: (filter: SnipbitSearchFilter, resultManipulation: SnipbitResultManipulation): Promise<Snipbit[]> => {
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
