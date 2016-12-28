/// Module for implementing useful utilities for testing.

import Bluebird from 'bluebird';

import { errorCodes } from '../src/types';


/**
 * Identical to the mocha `done` function.
 */
type mochaDone = (error?: any) => any;

/**
 * Helper to avoid putting a `done()` in the `.then` and a `.done(error)` in the
 * `.catch`.
 *
 * NOTE It seems that bluebird is typings don't allow it to be interchangable
 *      with promises even though they are, hence I have to cast it to avoid
 *      errors.
 */
export const assertPromiseDoesntError = (promise: Promise<any> | Bluebird<any>, done: mochaDone) => {
  (promise as Promise<any>)
  .then((result) => {
    done();
  })
  .catch((error) => {
    done(error);
  })
};

/**
 * Helper to avoid putting a `done('promise should have errored')` in the
 * `.then` and a `done()` in the catch.
 *
 * NOTE It seems that bluebird is typings don't allow it to be interchangable
 *      with promises even though they are, hence I have to cast it to avoid
 *      errors.
 */
export const assertPromiseDoesError = (
    promise: Promise<any> | Bluebird<any>,
    done: mochaDone)
    : void => {

  (promise as Promise<any>)
  .then((result) => {
    done("Promise should have errored");
  })
  .catch((error) => {
    done();
  });
};

/**
 * Similar to `assertPromiseDoesError` but also checks that the `errorCode` is
 * what we were expecting.
 */
export const assertPromiseErrorsWithCode = (
    promise: Promise<any> | Bluebird<any>,
    errorCode: errorCodes, done: mochaDone)
    : void => {

  (promise as Promise<any>)
  .then((result) => {
    done("Promise should have errored");
  })
  .catch((error: { errorCode: errorCodes }) => {
    if(error.errorCode == errorCode) {
      done();
    } else {
      done(`Promise should have errored with errorCode ${errorCode} but instead
        errored with errorCode ${error.errorCode}`);
    }
  });
}
