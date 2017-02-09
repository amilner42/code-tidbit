/// Module for encapsulating helper functions for the Snipbit model.

import * as kleen from "kleen";

import { malformedFieldError } from '../util';
import { collection } from '../db';
import { MongoID, ErrorCode, Language } from '../types';
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
}

/**
 * A highlighted comment in a Snipbit.
 */
export interface SnipbitHighlightedComment {
  comment: string;
  range: Range;
}

/**
* Kleen schema for a HighlightComment.
*/
const snipbitHighlightedCommentSchema: kleen.typeSchema = {
  objectProperties: {
    "comment": KS.commentSchema(ErrorCode.snipbitEmptyComment),
    "range": KS.rangeSchema(ErrorCode.snipbitEmptyRange)
  }
};

/**
* Kleen schema for a Snipbit.
*/
const snipbitSchema: kleen.typeSchema = {
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
export const validifyAndUpdateSnipbit = (snipbit: Snipbit): Promise<Snipbit> => {

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
}
