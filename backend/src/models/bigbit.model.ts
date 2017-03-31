/// Module for encapsulating helper functions for the Bigbit model.

import * as kleen from "kleen";
import moment from 'moment';
import { Cursor } from "mongodb";

import { malformedFieldError, asyncIdentity, isNullOrUndefined, dropNullAndUndefinedProperties } from '../util';
import { collection, renameIDField, toMongoObjectID, paginateResults } from '../db';
import { MongoID, MongoObjectID, ErrorCode, Language, TargetID } from '../types';
import { Range } from './range.model';
import { ContentSearchFilter, ContentResultManipulation, getContent } from "./content.model";
import { FileStructure, metaMap, swapPeriodsWithStars } from './file-structure.model';
import * as KS from './kleen-schemas';


/**
 * A Bigbit is one of the tidbits.
 */
export interface Bigbit {
  name: string;
  description: string;
  tags: string[];
  introduction: string;
  conclusion: string;
  highlightedComments: BigbitHighlightedComment[];

  // Added/modified by the backend.
  id?: MongoID; // When sending to the frontend, we switch `_id` to `id`.
  _id?: MongoID;
  fs : FileStructure<{},{},{ language : MongoID }>; // FileStructure from the frontend has language in string form, backend converts it to the ID.
  author?: MongoID;
  createdAt?: Date;
  lastModified?: Date;
};

/**
 * A highlighted comment in a bigbit.
 */
export interface BigbitHighlightedComment {
  file: String;
  comment: String;
  range: Range;
};

/**
 * The search options.
 */
export interface BigbitSearchFilter extends ContentSearchFilter { };

/**
 * The result manipulation options.
 */
export interface BigbitSearchResultManipulation extends ContentResultManipulation { }

/**
 * Kleen schema for `BigbitHighlightedComment`.
 */
const bigbitHighlightedCommentSchema: kleen.objectSchema = {
  objectProperties: {
    "file": KS.nonEmptyStringSchema(
      {
        errorCode: ErrorCode.bigbitEmptyFilePath,
        message: "All bigbit highlighted comments cannot have an empty string for a file"
      },
      malformedFieldError("file")
    ),
    "comment": KS.commentSchema(ErrorCode.bigbitEmptyComment),
    "range": KS.rangeSchema(ErrorCode.bigbitEmptyRange)
  },
  typeFailureError: malformedFieldError("highlightedComment")
};

/**
 * Kleen schema for a bigbit.
 */
const bigbitSchema: kleen.objectSchema = {
  objectProperties: {
    "name": KS.nameSchema(ErrorCode.bigbitEmptyName, ErrorCode.bigbitNameTooLong),
    "description": KS.descriptionSchema(ErrorCode.bigbitEmptyDescription),
    "tags": KS.tagsSchema(ErrorCode.bigbitEmptyTag, ErrorCode.bigbitNoTags),
    "introduction": KS.introductionSchema(ErrorCode.bigbitEmptyIntroduction),
    "conclusion": KS.conclusionSchema(ErrorCode.bigbitEmptyConclusion),
    "highlightedComments": KS.nonEmptyArraySchema(
      bigbitHighlightedCommentSchema,
      {
        errorCode: ErrorCode.bigbitNoHighlightedComments,
        message: "You must have at least one highlighted comment."
      },
      malformedFieldError("bigbit.highlightedComments")
    ),
    "fs": KS.fileStructureSchema(
      KS.emptyObjectSchema(
        malformedFieldError("fs metadata")
      ),
      KS.emptyObjectSchema(
        malformedFieldError("folder metadata")
      ),
      { objectProperties:
        {
          "language": KS.languageSchema(ErrorCode.bigbitInvalidLanguage)
        }
      }
    )
  },
  typeFailureError: malformedFieldError("bigbit")
};

/**
 * Validates a bigbit coming in from the frontend, and
 * updates it to the structure stored on the backend: the language on every
 * file must be switched to the MongoID AND all key names in the FS must have
 * their '.' replaced with '*' because mongoDB cannot have '.' in key names.
 *
 * NOTE: This function does not attach an author.
 */
const validifyAndUpdateBigbit = (bigbit: Bigbit): Promise<Bigbit> => {

  return new Promise((resolve, reject) => {

    kleen.validModel(bigbitSchema)(bigbit)
    .then(() => {
      return collection("languages");
    })
    .then((languageCollection) => {
      return metaMap(
        asyncIdentity,
        asyncIdentity,
        (fileMetadata => {
          return new Promise<{language: MongoID}>((resolveInner, rejectInner) => {
            (languageCollection.findOne({ encodedName: fileMetadata.language}) as Promise<Language>)
            .then((language) => {
              if(!language) {
                rejectInner(
                  {
                    errorCode: ErrorCode.bigbitInvalidLanguage,
                    message: `Language ${fileMetadata.language} is not a valid encoded language.`
                  }
                );
              }
              resolveInner({ language: language._id});
            })
            .catch(rejectInner);
          });
        }),
        bigbit.fs
      )
    })
    .then((updatedFS) => {
      bigbit.fs = swapPeriodsWithStars(true, updatedFS);
      resolve(bigbit);
    })
    .catch(reject);
  });
};

/**
 * Prepare a bigbit for the frontend, this includes:
 *  - Renaming _id to id
 *  - Switching languageIDs with language names.
 *  - Reversing the folder/file-names to once again have '.'
 *
 * @WARNING Mutates `bigbit`.
 */
const prepareBigbitForResponse = (bigbit: Bigbit): Promise<Bigbit> => {
  renameIDField(bigbit);

  return collection("languages")
  .then((languageCollection) => {
    // Swap all languageIDs with encoded language names.
    return metaMap(
      asyncIdentity,
      asyncIdentity,
      (fileMetadata => {
        return new Promise<{language: string}>((resolve, reject) => {
          languageCollection.findOne({ _id: toMongoObjectID(fileMetadata.language) })
          .then((language: Language) => {
            if(!language) {
              reject({
                errorCode: ErrorCode.internalError,
                message: `Language ID ${fileMetadata.language} does not point to a language`
              });
              return;
            }

            resolve({ language: language.encodedName });
            return;
          });
        });
      }),
      bigbit.fs
    );
  })
  .then((updatedFS) => {
    // Switch to updated fs, which includes swapping '*' with '.'
    bigbit.fs = swapPeriodsWithStars(false, updatedFS);
    return bigbit;
  });
};

/**
 * All the db helpers for a bigbit.
 */
export const bigbitDBActions = {

  /**
   * Adds a new bigbit to the database for a user. Handles all the logic of
   * changing the languages to the IDs and renaming files/folders to avoid
   * having a "." in them.
   */
  addNewBigbit: (userID: MongoID, bigbit: Bigbit): Promise<TargetID> => {
    return validifyAndUpdateBigbit(bigbit)
    .then((updatedBigbit: Bigbit) => {
      const dateNow = moment.utc().toDate();

      updatedBigbit.author = userID;
      updatedBigbit.createdAt = dateNow;
      updatedBigbit.lastModified = dateNow;

      return collection("bigbits")
      .then((bigbitCollection) => {
        return bigbitCollection.insertOne(updatedBigbit);
      })
      .then((insertBigbitResult) => {
        return { targetID: insertBigbitResult.insertedId };
      });
    });
  },

  /**
   * Gets bigbits, customizable through the `BigbitSearchFilter` and `BigbitSearchResultManipulation`.
   */
  getBigbits: (filter: BigbitSearchFilter, resultManipulation: BigbitSearchResultManipulation): Promise<Bigbit[]> => {
    return getContent<Bigbit>(collection("bigbits"), filter, resultManipulation, prepareBigbitForResponse);
  },

  /**
   * Gets a bigbit from the database, handles all the transformations to get the
   * bigbit in the correct format for the frontend (reverse transformations of
   * `addNewBigbit`).
   */
  getBigbit: (bigbitID: MongoID): Promise<Bigbit> => {
    return collection("bigbits")
    .then<Bigbit>((bigbitCollection) => {
      return bigbitCollection.findOne({ _id: toMongoObjectID(bigbitID) });
    })
    .then((bigbit) => {

      if(!bigbit) {
        return Promise.reject({
          errorCode: ErrorCode.bigbitDoesNotExist,
          message: `ID ${bigbitID} does not point to a bigbit.`
        });
      }

      return prepareBigbitForResponse(bigbit);
    });
  },

  /**
   * Checks if a bigbit exists.
   */
  hasBigbit: (bigbitID: MongoID): Promise<boolean> => {
    return collection("bigbits")
    .then((bigbitCollection) => {
      return bigbitCollection.count({ _id: toMongoObjectID(bigbitID) });
    })
    .then((numberOfBigbitsWithID) => {
      return numberOfBigbitsWithID > 0;
    });
  }
}
