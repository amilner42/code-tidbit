/// Module for implementing useful utilities.

import { ErrorCode } from './types';

/**
 * Returns true if `thing` is null or undefined.
 */
export const isNullOrUndefined: isNullOrUndefined = (thing: any) => {
  return (thing == null || thing == undefined);
}

/**
 * Helper for creating internal errors.
 */
export const internalError = (message: string) => {
  return {
    errorCode: ErrorCode.internalError,
    message
  };
};

/**
 * Helper for creating `x is malformed` internal errors.
 */
export const malformedFieldError = (fieldName: string) => {
  return {
    errorCode: ErrorCode.internalError,
    message: `${fieldName} is malformed, refer to the API for the proper format.`
  }
};

/**
 * A typed object map that returns a new object.
 */
export const objectMap = <a, a1>(obj: {[key: string]: a}, func: (a: a) => a1): {[key: string]: a1} => {
  var result = {};
  for(let key in obj) {
    result[key] = func(obj[key]);
  }
  return result;
};

/**
 * Similar to a regular identity function, but async, always resolves.
 */
export const asyncIdentity = <T1>(val: T1): Promise<T1> => {
  return Promise.resolve(val);
};

/**
 * Creates a new objects from the given `obj`, containing all the same fields
 * except drops all fields which have a value of null/undefined.
 */
export const dropNullAndUndefined = (obj) => {
  const newObj = {};

  for(let key in obj) {
    if(obj[key] !== null && obj[key] !== undefined) {
      newObj[key] = obj[key];
    }
  }

  return newObj;
};
