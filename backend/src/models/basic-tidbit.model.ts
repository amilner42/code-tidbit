import * as kleen from "kleen";

import { MongoID } from '../types';


/**
 * A BasicTidbit is one of the possible tidbit types.
 */
export interface BasicTidbit {
  language: MongoID;
  name: string;
  description: string;
  tags: string[];
  code: string;
  introduction: string;
  conclusion: string;
  highlightedComments: HighlightedComment[];
}

/**
 * A highlighted comment in a BasicTidbit.
 */
export interface HighlightedComment {
  comment: string;
  range: {
    startRow: string;
    startCol: string;
    endRow: string;
    endCol: string;
  }
}

/**
* Kleen validator for a HighlightComment.
*/
const HighlightedCommentSchema = {
  objectProperties: {
    "comment": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "range": {
      objectProperties: {
        "startRow": {
          primitiveType: kleen.kindOfPrimitive.string
        },
        "startCol": {
          primitiveType: kleen.kindOfPrimitive.string
        },
        "endRow": {
          primitiveType: kleen.kindOfPrimitive.string
        },
        "endCol": {
          primitiveType: kleen.kindOfPrimitive.string
        }
      }
    }
  }
};

/**
* Kleen validator for a BasicTidbit.
*/
const BasicTidbitSchema = {
  objectProperties: {
    "language": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "name": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "description": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "tags": {
      arrayElementType: {
        primitiveType: kleen.kindOfPrimitive.string
      }
    },
    "code": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "introduction": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "conclusion": {
      primitiveType: kleen.kindOfPrimitive.string
    },
    "highlightedComments": {
      arrayElementType: HighlightedCommentSchema
    }
  }
};
