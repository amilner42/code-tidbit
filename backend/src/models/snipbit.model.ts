/// Module for encapsulating helper functions for the Snipbit model.

import * as kleen from "kleen";

import { internalError } from '../util';
import { collection } from '../db';
import { MongoID, ErrorCode, Language } from '../types';


/**
 * A Snipbit is one of the tidbits.
 */
export interface Snipbit {
  language: MongoID;
  name: string;
  description: string;
  tags: string[];
  code: string;
  introduction: string;
  conclusion: string;
  highlightedComments: HighlightedComment[];

  // Added by the backend.
  id?: MongoID; // When sending to the frontend, we switch `_id` to `id`.
  _id?: MongoID;
  author?: MongoID;
}

/**
 * A highlighted comment in a Snipbit.
 */
export interface HighlightedComment {
  comment: string;
  range: Range;
}

/**
 * A range represents a range from the ACE API.
 */
export interface Range {
  startRow: number;
  startCol: number;
  endRow: number;
  endCol: number;
}

// Name's of snipbits shouldn't be more than 60 chars.
const MAX_NAME_LENGTH = 60;

/**
 * Checks if a range is empty.
 *
 * @returns True if range is empty or null.
 */
const emptyRange = (range: Range): boolean => {
  if(!range) {
    return true;
  }

  return (range.startRow === range.endRow) && (range.startCol === range.endCol);
};

/**
* Kleen schema for a HighlightComment.
*/
const highlightedCommentSchema: kleen.typeSchema = {
  objectProperties: {
    "comment": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (comment: string) => {
        if(comment === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyComment,
            message: "Comments cannot be empty"
          });
        }
      },
      typeFailureError: internalError("Comment must be string, refer to the API.")
    },
    "range": {
      objectProperties: {
        "startRow": {
          primitiveType: kleen.kindOfPrimitive.number,
          typeFailureError: internalError("Range startRow must be a number, refer to the API.")
        },
        "startCol": {
          primitiveType: kleen.kindOfPrimitive.number,
          typeFailureError: internalError("Range startCol must be a number, refer to the API.")
        },
        "endRow": {
          primitiveType: kleen.kindOfPrimitive.number,
          typeFailureError: internalError("Range endRow must be a number, refer to the API.")
        },
        "endCol": {
          primitiveType: kleen.kindOfPrimitive.number,
          typeFailureError: internalError("Range endCol must be a number, refer to the API.")
        }
      },
      restriction: (range: Range) => {
        if(emptyRange(range)) {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyRange,
            message: "Ranges on highlighted comments can not be empty!"
          });
        }
      },
      typeFailureError: internalError("Range format invalid, refer to API.")
    }
  }
};

/**
* Kleen schema for a Snipbit.
*/
const snipbitSchema: kleen.typeSchema = {
  objectProperties: {
    "language": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (language: string) => {
        if(language === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitInvalidLanguage,
            message: "Empty language is not a valid language."
          });
        }
      },
      typeFailureError: internalError("Language must be a string, refer to API.")
    },
    "name": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (name: string) => {
        if(name === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyName,
            message: "Name cannot be empty."
          });
        } else if(name.length > MAX_NAME_LENGTH) {
          return Promise.reject({
            errorCode: ErrorCode.snipbitNameTooLong,
            message: "Name cannot be more than 60 chars."
          });
        }
      },
      typeFailureError: internalError("Name must be a string, refer to API.")
    },
    "description": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (description: string) => {
        if(description === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyDescription,
            message: "Description cannot be empty."
          });
        }
      },
      typeFailureError: internalError("Description must be a string, refer to API.")
    },
    "tags": {
      arrayElementType: {
        primitiveType: kleen.kindOfPrimitive.string,
        restriction: (tag: string) => {
          if(tag === "") {
            return Promise.reject({
              errorCode: ErrorCode.snipbitEmptyTag,
              message: "Tags cannot be empty!"
            });
          }
        },
        typeFailureError: internalError("Tag must be a string, refer to API.")
      },
      restriction: (tags: string[]) => {
        if(tags.length === 0) {
          return Promise.reject({
            errorCode: ErrorCode.snipbitNoTags,
            message: "You must add at least one tag"
          });
        }
      },
      typeFailureError: internalError("Tags must be an array of strings, refer to API.")
    },
    "code": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (code: string) => {
        if(code === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyCode,
            message: "You must have some code!"
          });
        }
      },
      typeFailureError: internalError("Code must be a string, refer to API.")
    },
    "introduction": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (introduction: string) => {
        if(introduction === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyIntroduction,
            message: "You must have a non-empty introduction."
          });
        }
      },
      typeFailureError: internalError("Introduction must be a string, refer to API.")
    },
    "conclusion": {
      primitiveType: kleen.kindOfPrimitive.string,
      restriction: (conclusion: string) => {
        if(conclusion === "") {
          return Promise.reject({
            errorCode: ErrorCode.snipbitEmptyConclusion,
            message: "You must have a non-empty conclusion."
          });
        }
      },
      typeFailureError: internalError("Conclusion must be a string, refer to API.")
    },
    "highlightedComments": {
      arrayElementType: highlightedCommentSchema,
      restriction: (highlightedComments: HighlightedComment[]) => {
        if(highlightedComments.length === 0) {
          return Promise.reject({
            errorCode: ErrorCode.snipbitNoHighlightedComments,
            message: "You must have at least one highlighted comment."
          });
        }
      },
      typeFailureError: internalError("HighlightedComments must be an array of HighlightedComment, refer to API.")
    }
  },
  typeFailureError: internalError("Snipbit is malformed, refer to API for proper format.")
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
          message: `Language ${language} is not a valid encoded language.`
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
