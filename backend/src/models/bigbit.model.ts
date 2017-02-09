/// Module for encapsulating helper functions for the Bigbit model.

import * as kleen from "kleen";

import { internalError, malformedFieldError } from '../util';
import { collection } from '../db';
import { MongoID, ErrorCode, Language } from '../types';
import { Range } from './range.model';
import { FileStructure, metaMap, swapPeriodsWithStarsForFS } from './file-structure.model';
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
 * Kleen schema for `BigbitHighlightedComment`.
 */
const bigbitHighlightedCommentSchema: kleen.typeSchema= {
  objectProperties: {
    "file": KS.nonEmptyStringSchema(
      { errorCode: undefined, message: "All bigbit highlighted comments cannot have an empty string for a file" },
      malformedFieldError("file")
    ),
    "comment": KS.commentSchema(undefined),
    "range": KS.rangeSchema(undefined)
  },
  typeFailureError: malformedFieldError("highlightedComment")
};

/**
 * Kleen schema for a bigbit.
 *
 * TODO switch `undefined` to actual errorCodes.
 */
export const bigbitSchema: kleen.typeSchema = {
  objectProperties: {
    "name": KS.nameSchema(undefined, undefined),
    "description": KS.descriptionSchema(undefined),
    "tags": KS.tagsSchema(undefined, undefined),
    "introduction": KS.introductionSchema(undefined),
    "conclusion": KS.conclusionSchema(undefined),
    "highlightedComments": KS.nonEmptyArraySchema(
      bigbitHighlightedCommentSchema,
      { errorCode: undefined, message: "You must have at least one highlighted comment."},
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
          "language": KS.languageSchema(undefined)
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
export const validifyAndUpdateBigbit = (bigbit: Bigbit) => {

  const asyncIdentity = <T1>(val: T1): Promise<T1> => {
    return Promise.resolve(val);
  };

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
                rejectInner({ errorCode: undefined, message: `Language ${fileMetadata.language} is not a valid encoded language.`})
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
      bigbit.fs = swapPeriodsWithStarsForFS(true, updatedFS);
      resolve(bigbit);
    })
    .catch(reject);
  });
}
