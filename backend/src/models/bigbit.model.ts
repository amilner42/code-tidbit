/// Module for encapsulating helper functions for the Bigbit model.

import * as kleen from "kleen";
import moment from 'moment';
import { Cursor } from "mongodb";
import * as R from "ramda";

import { opinionDBActions } from "./opinion.model";
import { malformedFieldError, asyncIdentity, isNullOrUndefined, dropNullAndUndefinedProperties } from '../util';
import { collection, renameIDField, toMongoObjectID, paginateResults } from '../db';
import { MongoID, MongoObjectID, ErrorCode, TargetID } from '../types';
import { Range } from './range.model';
import { ContentSearchFilter, ContentResultManipulation, ContentType, ContentPointer, getContent } from "./content.model";
import { FileStructure, swapPeriodsWithStars, fileFold } from './file-structure.model';
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
  fs : FileStructure<{},{},{ language : string }>;
  author?: MongoID;
  authorEmail?: string;
  languages?: string[];
  createdAt?: Date;
  lastModified?: Date;
  likes?: number;     // In the `opinions` collection, attached by the backend.
  dislikes?: number;  // In the `opinions` collection, attached by the backend.
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
    "description": KS.descriptionSchema(ErrorCode.bigbitEmptyDescription, ErrorCode.bigbitDescriptionTooLong),
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
      KS.emptyObjectSchema(malformedFieldError("fs metadata")),
      KS.emptyObjectSchema(malformedFieldError("folder metadata")),
      { objectProperties: { "language": KS.languageSchema(ErrorCode.bigbitInvalidLanguage) } }
    )
  },
  typeFailureError: malformedFieldError("bigbit")
};

/**
 * Prepare a bigbit for the frontend, this includes:
 *  - Renaming _id to id
 *  - Reversing the folder/file-names to once again have '.'
 *  - Fetching and attaching likes/dislikes.
 */
const prepareBigbitForResponse = (bigbit: Bigbit): Promise<Bigbit> => {
  const bigbitCopy = R.clone(bigbit);
  const contentPointer: ContentPointer = {
    contentType: ContentType.Bigbit,
    contentID: bigbitCopy._id.toString()
  };

  bigbitCopy.fs = swapPeriodsWithStars(false, bigbitCopy.fs);

  return opinionDBActions.getAllOpinionsOnContent(contentPointer)
  .then(({ likes, dislikes }) => {
    bigbitCopy.likes = likes;
    bigbitCopy.dislikes = dislikes;

    return renameIDField(bigbitCopy);
  });
};

/**
 * Get's all the languages used in a bigbit (unique).
 */
const getLanguagesUsedInBigbit = (bigbit: Bigbit): string[] => {
  return Array.from(
    fileFold(
      bigbit.fs,
      new Set<string>([]),
      (metadata, currentLanguages) => { return currentLanguages.add(metadata.language); }
    )
  );
}

/**
 * All the db helpers for a bigbit.
 */
export const bigbitDBActions = {

  /**
   * Adds a new bigbit to the database for a user. Handles:
   *  - renaming files/folders to avoid having a "." in them
   *  - Adds `createdAt` and `lastModified` timestamps
   *  - Adds user id as `author`
   *  - Adds user email as `authorEmail`
   *  - Adds a `languages` field containing all the languages used in the bigbit
   */
  addNewBigbit: (userID: MongoID, userEmail: string, bigbit: Bigbit): Promise<TargetID> => {
    return kleen.validModel(bigbitSchema)(bigbit)
    .then(() => {
      bigbit.fs = swapPeriodsWithStars(true, bigbit.fs);
      return bigbit;
    })
    .then((updatedBigbit: Bigbit) => {
      const dateNow = moment.utc().toDate();

      updatedBigbit.author = userID;
      updatedBigbit.authorEmail = userEmail;
      updatedBigbit.createdAt = dateNow;
      updatedBigbit.lastModified = dateNow;
      updatedBigbit.languages = getLanguagesUsedInBigbit(updatedBigbit);

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
    return getContent<Bigbit>(ContentType.Bigbit, filter, resultManipulation, prepareBigbitForResponse);
  },

  /**
   * Gets a bigbit from the database, prepares the bigbit for the response.
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

      return Promise.resolve(prepareBigbitForResponse(bigbit));
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
