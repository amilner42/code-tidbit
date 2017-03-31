/// Module for encapsulating helper functions for the Snipbit model.

import * as kleen from "kleen";
import moment from 'moment';

import { malformedFieldError, isNullOrUndefined, dropNullAndUndefinedProperties } from '../util';
import { collection, renameIDField, toMongoObjectID, paginateResults } from '../db';
import { MongoID, MongoObjectID, ErrorCode, Language, TargetID } from '../types';
import { ContentSearchFilter, ContentResultManipulation, getContent } from "./content.model";
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
  language: MongoID; // Backend converts language string to MongoID of language in DB.
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
    "description": KS.descriptionSchema(ErrorCode.snipbitEmptyDescription),
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
 * Validates a snipbit coming in from the frontend, and
 * updates it to the structure stored on the backend (the language
 * must be switched to the MongoID).
 *
 * NOTE: This function does not attach an author.
 */
const validifyAndUpdateSnipbit = (snipbit: Snipbit): Promise<Snipbit> => {

  return new Promise<Snipbit>((resolve, reject) => {

    kleen.validModel(snipbitSchema)(snipbit)
    .then(() => {
      return collection("languages");
    })
    .then((languagesCollection) => {
      return (languagesCollection.findOne({ encodedName: snipbit.language }) as Promise<Language>);
    })
    .then((language: Language) => {
      if(!language) {
        reject({
          errorCode: ErrorCode.snipbitInvalidLanguage,
          message: `Language ${snipbit.language} is not a valid encoded language.`
        });
        return;
      }

      snipbit.language = language._id;
      resolve(snipbit);
      return;
    })
    .catch(reject);
  });
};

/**
 * Prepares a snipbit for the frontend. This includes renaming the `_id` field
 * as well as switching the language ID with the encoded name.
 *
 * @WARNING Mutates `snipbit`.
 */
const prepareSnipbitForResponse = (snipbit: Snipbit): Promise<Snipbit> => {
  renameIDField(snipbit);

  return new Promise((resolve, reject) => {

    collection("languages")
    .then<Language>((languageCollection) => {
      return languageCollection.findOne({ _id: toMongoObjectID(snipbit.language) });
    })
    .then((language) => {

      if(!language) {
        reject({
          errorCode: ErrorCode.internalError,
          message: `Language ID ${snipbit.language} was invalid`
        });
        return;
      }

      // Update language to encoded language name.
      snipbit.language = language.encodedName;
      resolve(snipbit);
    })
    .catch(reject);
  });
};

/**
 * All the db helpers for a snipbit.
 */
export const snipbitDBActions = {

  /**
   * Adds a new snipbit for a user. Handles all logic of converting snipbits to
   * proper format (attaching an author, converting languages).
   */
  addNewSnipbit: (userID: MongoID, snipbit: Snipbit): Promise<TargetID> => {
    return validifyAndUpdateSnipbit(snipbit)
    .then((updatedSnipbit: Snipbit) => {
      const dateNow = moment.utc().toDate();

      updatedSnipbit.author = userID;
      updatedSnipbit.createdAt = dateNow;
      updatedSnipbit.lastModified = dateNow;

      return collection("snipbits")
      .then((snipbitCollection) => {
        return snipbitCollection.insertOne(updatedSnipbit);
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
    return getContent(collection("snipbits"), filter, resultManipulation, prepareSnipbitForResponse);
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

      return prepareSnipbitForResponse(snipbit);
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
