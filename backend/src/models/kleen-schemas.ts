/// Module for all abstract kleen schemas to be used in multiple models.

import * as kleen from "kleen";
import { Range, emptyRange } from './range.model';
import { malformedFieldError, internalError } from '../util';
import { ErrorCode, FrontendError } from '../types';
import { validMongoID  } from '../validifier';


/**
 * TODO move this into Kleen.
 */
type RestrictableSchema
  = kleen.primitiveSchema
  | kleen.objectSchema
  | kleen.arraySchema
  | kleen.referenceSchema
  | kleen.mapSchema;

// Mutation Helpers START

/**
 * Mutates a schema to allow undefined.
 *
 * @WARNING mutates `schema`
 */
export const allowUndefined = (schema: kleen.typeSchema): kleen.typeSchema => {
  schema.undefinedAllowed = true;
  return schema;
};

/**
 * Mutates a schema to allow null.
 *
 * @WARNING mutates `schema`.
 */
export const allowNull = (schema: kleen.typeSchema): kleen.typeSchema => {
  schema.nullAllowed = true;
  return schema;
}

/**
 * Mutates a schema to allow null/undefined.
 *
 * @WARNING muates `schema`
 */
export const optional = (schema: kleen.typeSchema): kleen.typeSchema => {
  return allowUndefined(allowNull(schema));
}

/**
 * Mutates a schema to use the given restriction. Will overwrite previous
 * restrictions.
 */
export const withRestriction = (schema: RestrictableSchema , restriction: (any: any) => void | Promise<void>): kleen.typeSchema  => {
  schema.restriction = restriction;
  return schema;
}

// Mutation helpers END

/**
 * Helper for validifying an empty object.
 */
export const emptyObjectSchema = (typeInvalidApiError: FrontendError): kleen.typeSchema => {
  return {
    objectProperties: {},
    typeFailureError: typeInvalidApiError
  }
};

/**
 * Helper for building kleen schemas that validate that string is not empty.
 */
export const nonEmptyStringSchema = (emptyStringApiError: FrontendError, typeInvalidApiError: FrontendError): RestrictableSchema => {
  return {
    primitiveType: kleen.kindOfPrimitive.string,
    restriction: (someString: string) => {
      if(someString === "") {
        return Promise.reject(emptyStringApiError);
      }
    },
    typeFailureError: typeInvalidApiError
  }
};

/**
 * Helper for building kleen schemas that validate a non-empty array.
 */
export const nonEmptyArraySchema =
  (arrayElementType: kleen.typeSchema,
  emptyArrayApiError: FrontendError,
  typeInvalidApiError: FrontendError)
  : kleen.typeSchema => {

  return {
    arrayElementType,
    restriction: (arrayOfSomething: any[]) => {
      if(arrayOfSomething.length === 0) {
        return Promise.reject(emptyArrayApiError)
      }
    },
    typeFailureError: typeInvalidApiError
  }
};

/**
* For validifying ranges, including making sure they aren't empty.
*/
export const rangeSchema = (emptyRangeErrorCode: ErrorCode): kleen.typeSchema => {
  return {
    objectProperties: {
      "startRow": {
        primitiveType: kleen.kindOfPrimitive.number,
        typeFailureError: malformedFieldError("range.startRow")
      },
      "startCol": {
        primitiveType: kleen.kindOfPrimitive.number,
        typeFailureError: malformedFieldError("range.startCol")
      },
      "endRow": {
        primitiveType: kleen.kindOfPrimitive.number,
        typeFailureError: malformedFieldError("range.endRow")
      },
      "endCol": {
        primitiveType: kleen.kindOfPrimitive.number,
        typeFailureError: malformedFieldError("range.endCol")
      }
    },
    restriction: (range: Range) => {
      if(emptyRange(range)) {
        return Promise.reject({
          errorCode: emptyRangeErrorCode,
          message: "Ranges on highlighted comments can not be empty!"
        });
      }
    },
    typeFailureError: malformedFieldError("range")
  }
};

/**
 * For validifying comments, including making sure they aren't empty.
 */
export const commentSchema = (emptyCommentErrorCode: ErrorCode): kleen.typeSchema => {
  return nonEmptyStringSchema(
    { errorCode: emptyCommentErrorCode, message: "Comments cannot be empty"},
    malformedFieldError("comment")
  );
};

/**
 * For validifying a language, doesn't check the language is a valid language
 * but does check that it isn't emtpy.
 */
export const languageSchema = (emptyLanguageErrorCode: ErrorCode): kleen.typeSchema => {
  return nonEmptyStringSchema(
    { errorCode: emptyLanguageErrorCode, message: "Empty language is not a valid language." },
    malformedFieldError("language")
  );
};

/**
 * For validifying a name, makes sure the name is not too short or too long.
 */
export const nameSchema = (emptyNameErrorCode: ErrorCode, nameTooLongErrorCode: ErrorCode): kleen.typeSchema => {
  return {
    primitiveType: kleen.kindOfPrimitive.string,
    restriction: (name: string) => {
      if(name === "") {
        return Promise.reject({
          errorCode: emptyNameErrorCode,
          message: "Name cannot be empty."
        });
      } else if(name.length > 60) {
        return Promise.reject({
          errorCode: nameTooLongErrorCode,
          message: `Name cannot be more than 60 chars.`
        });
      }
    },
    typeFailureError: malformedFieldError("name")
  }
};

/**
 * For validifying a description, makes sure it is not empty.
 */
export const descriptionSchema = (emptyDescriptionErrorCode: ErrorCode): kleen.typeSchema => {
  return nonEmptyStringSchema(
    { errorCode: emptyDescriptionErrorCode, message: "Description cannot be empty."},
    malformedFieldError("description")
  )
};

/**
 * For validifying tags, making sure that there is at least one tag and that
 * every tag is not empty.
 */
export const tagsSchema = (emptyTagErrorCode, noTagsErrorCode): kleen.typeSchema => {
  return nonEmptyArraySchema(
    nonEmptyStringSchema(
      {
        errorCode: emptyTagErrorCode,
        message: "Tags cannot be empty!"
      },
      malformedFieldError("tag")
    ),
    {
      errorCode: noTagsErrorCode,
      message: "You must add at least one tag"
    },
    malformedFieldError("tags"),
  );
};

/**
 * For validifying code, making sure that there is at least some code.
 */
export const codeSchema = (codeEmptyErrorCode: ErrorCode): kleen.typeSchema => {
  return nonEmptyStringSchema(
    { errorCode: codeEmptyErrorCode, message:  "You must have some code!" },
     malformedFieldError("code")
  );
};

/**
 * For validifying an introduction, makes sure it isn't empty.
 */
export const introductionSchema = (emptyIntroErrorCode: ErrorCode): kleen.typeSchema => {
  return nonEmptyStringSchema(
    { errorCode: emptyIntroErrorCode, message: "You must have a non-empty introduction." },
     malformedFieldError("introduction")
  );
};

/**
 * For validifying a conclusion, makes sure that it isn't empty.
 */
export const conclusionSchema = (emptyConclusionErrorCode: ErrorCode): kleen.typeSchema => {
  return nonEmptyStringSchema(
    { errorCode: emptyConclusionErrorCode, message: "You must have a non-empty conclusion." },
     malformedFieldError("conclusion")
  );
};

/**
 * For validifying a FileStructure.
 *
 * On top of expected checks, also makes sure that no file/folder names have a
 * '*' in them because mongo can't have periods in key names.
 */
export const fileStructureSchema =
  (fsMetadataSchema: kleen.typeSchema,
  folderMetadataSchema: kleen.typeSchema,
  fileMetadataSchema: kleen.typeSchema
  ): kleen.typeSchema => {

  const mapHasStarInKeys = (someMap: {[key: string]: any}): boolean => {
    for(let key in someMap) {
      if(key.includes("*")) {
        return true;
      }
    }
    return false;
  };

  return {
    objectProperties: {
      "rootFolder": {
        objectProperties: {
          "files": {
            mapValueType: {
              objectProperties: {
                "content": {
                  primitiveType: kleen.kindOfPrimitive.string
                },
                "fileMetadata": fileMetadataSchema
              },
              typeFailureError: malformedFieldError("file")
            },
            restriction: (files) => {
              if(mapHasStarInKeys(files)) {
                return Promise.reject(internalError("File names cannot contain '*'"));
              }
            },
            typeFailureError: malformedFieldError("files")
          },
          "folders": {
            mapValueType: {
              referenceName: "folderSchema"
            },
            restriction: (folders) => {
              if(mapHasStarInKeys(folders)) {
                return Promise.reject(internalError("Folder names cannot contain '*'"))
              }
            },
            typeFailureError: malformedFieldError("folders")
          },
          "folderMetadata": folderMetadataSchema
        },
        name: "folderSchema",
        typeFailureError: malformedFieldError("folder")
      },
      "fsMetadata": fsMetadataSchema
    },
    typeFailureError: malformedFieldError("file structure")
  }
};

/**
 * A mongo id schema, will error with `error`.
 *
 * WARNING: Will only validify strings, not `ObjectID`s.
 */
export const mongoIDSchema = (invalidMongoIDError: any): kleen.primitiveSchema => {
  return {
    primitiveType: kleen.kindOfPrimitive.string,
    typeFailureError: invalidMongoIDError,
    restriction: (mongoID: string) => {
      if(!validMongoID(mongoID)) {
        return Promise.reject(invalidMongoIDError);
      }
    }
  }
};
