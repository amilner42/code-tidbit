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
