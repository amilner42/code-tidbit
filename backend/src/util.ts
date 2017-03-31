/// Module for implementing useful utilities.

import * as R from "ramda";

import { ErrorCode } from './types';

/**
 * Returns true if `thing` is null or undefined.
 */
export const isNullOrUndefined: isNullOrUndefined = (thing: any) => {
  return (thing === null || thing === undefined);
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
export const dropNullAndUndefinedProperties = (obj) => {
  const newObj = {};

  for(let key in obj) {
    if(obj[key] !== null && obj[key] !== undefined) {
      newObj[key] = obj[key];
    }
  }

  return newObj;
};

/**
 * Combines 2 arrays of seperate types into 1 array of a union type.
 */
export const combineArrays = <T1, T2>(array1: T1[], array2: T2[]): (T1 | T2)[] => {
  return (array1 as (T1 | T2)[]).concat(array2);
}

/**
 * Sort by date, newest first.
 */
export const sortByNewestDate = <T1>(getDate: ((t1: T1) => Date), listOfT1: T1[]): T1[] => {
  return R.sort<T1>((left, right) => {
    return  getDate(right).getTime() - getDate(left).getTime();
  })(listOfT1);
}
