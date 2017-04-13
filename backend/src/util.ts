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
 * Useful for functional pipes.
 */
export const getTime = (date: Date): number => {
  return date.getTime();
}

/**
 * For getting a number from a orderable-comparison, useful for sorting.
 */
export const numberFromComparison = <T1>(sortOrder: SortOrder, left: T1, right: T1): number => {
  let resultNumber;

  if (left < right) {
    resultNumber = 1;
  } else if (left > right) {
    resultNumber = -1;
  } else {
    resultNumber = 0;
  }

  return (sortOrder === SortOrder.Descending) ? resultNumber : resultNumber * -1;
}

/**
 * The different sort orders.
 */
export enum SortOrder {
  Ascending = 1,
  Descending
};

/**
 * A `Sorter` gives a specification for sorting, containing the information to get an orderable value from an object and
 * also specifying whether to go in ascending or descending order.
 */
export type Sorter<T1> = [ SortOrder, (val: T1) => any ];

/**
 * Sorts a list given a list of `Sorter`s, will start by sorting by the first `Sorter` and will use remaining `Sorter`s
 * to break ties when needed.
 */
export const sortByAll = <T1>(sorters: Sorter<T1>[], listOfT1: T1[]) => {
  return R.sort<T1>((left, right) => {
    let result = 0;
    for (let i = 0; result === 0 && i < sorters.length; i++) {
      const [sortOrder, sortBy] = sorters[i];
      result = numberFromComparison(sortOrder, sortBy(left),  sortBy(right));
    }
    return result;
  })(listOfT1);
};

/**
 * A classic (`Maybe.map` in Elm) to be able to handle null/undefined better.
 */
export const maybeMap = <ArgType,ReturnType>(func: (arg: ArgType) => ReturnType): (arg: ArgType) => ReturnType => {

  return (arg: ArgType): ReturnType => {
    if(isNullOrUndefined(arg)) {
      return null;
    }

    return func(arg);
  }
};

/**
 * Filters words in a sentence based on `keepWord`.
 */
export const filterWords = (sentence: string, keepWord: (word: string) => boolean): string  => {
  return R.pipe(
    R.split(" "),
    R.filter(keepWord),
    R.join(" ")
  )(sentence);
};

/**
 * Returns true if the string is null/undefined/empty/just-spaces.
 */
export const isBlankString = (str: string): boolean => {
  if(isNullOrUndefined(str)) {
    return true;
  }

  return R.isEmpty(R.filter((char) => char !== " ", str.split("")));
}
