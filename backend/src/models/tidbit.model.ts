/// Module for encapsulating helper functions for the tidbit model.

import * as kleen from "kleen";

import { malformedFieldError, isNullOrUndefined } from '../util';
import { ErrorCode, MongoID, MongoObjectID } from '../types';
import { mongoIDSchema } from './kleen-schemas';
import { Snipbit, snipbitDBActions } from './snipbit.model';
import { Bigbit, bigbitDBActions } from './bigbit.model';


/**
 * The internal tidbit search filter.
 */
interface InternalTidbitSearchFilter {
  author?: MongoObjectID;
}

/**
 * All the possible tidbits.
 */
export type Tidbit = Snipbit | Bigbit;

/**
* A `TidbitPointer` points to a tidbit, providing the means to retrieve the
* tidbit when needed.
*/
export interface TidbitPointer {
  tidbitType: TidbitType;
  targetID: MongoID;
}

/**
* The current possible tidbit types.
*/
export enum TidbitType {
  Snipbit = 1,
  Bigbit
}

/**
 * The filters allowed when getting tidbits.
 */
export interface TidbitSearchFilter {
  forUser?: MongoID;
}

/**
* The schema for validating a `TidbitPointer`.
*/
export const tidbitPointerSchema: kleen.typeSchema = {
  objectProperties: {
    "tidbitType": {
      primitiveType: kleen.kindOfPrimitive.number,
      restriction: (tidbitType: number) => {
        if(!(tidbitType in TidbitType)) {
          return Promise.reject({
            errorCode: ErrorCode.storyInvalidTidbitType,
            message: "Invalid tidbit type"
          });
        }
      },
      typeFailureError: malformedFieldError("tidbitPointer.tidbitType")
    },
    "targetID": mongoIDSchema(malformedFieldError("tidbitPointer.targetID")),
  }
};

/**
 * All the db helpers for tidbits and tidbitPointers.
 */
export const tidbitDBActions = {

   /**
    * Returns [a promise to] true if the `tidbitPointer` points to an existant
    * tidbit.
    */
   tidbitPointerExists: (tidbitPointer: TidbitPointer): Promise<boolean> => {
     switch(tidbitPointer.tidbitType) {
       case TidbitType.Snipbit:
         return snipbitDBActions.hasSnipbit(tidbitPointer.targetID);

       case TidbitType.Bigbit:
         return bigbitDBActions.hasBigbit(tidbitPointer.targetID);
     }
   },

   /**
    * Gets the actual tidbit from the appropriate collection.
    */
  expandTidbitPointer: (tidbitPointer: TidbitPointer): Promise<Tidbit> => {
    switch(tidbitPointer.tidbitType) {
      case TidbitType.Snipbit:
        return snipbitDBActions.getSnipbit(tidbitPointer.targetID);

      case TidbitType.Bigbit:
        return bigbitDBActions.getBigbit(tidbitPointer.targetID);
    }
  },

  /**
   * Gets tidbits from the database, customizable through search filter.
   */
  getTidbits: (searchFilter: TidbitSearchFilter): Promise<Tidbit[]> => {

    return Promise.all([snipbitDBActions.getSnipbits(searchFilter), bigbitDBActions.getBigbits(searchFilter)])
    .then(([snipbits, bigbits]) => {
      let tidbits: (Snipbit | Bigbit)[] = snipbits;
      tidbits = tidbits.concat(bigbits);

      return tidbits;
    });
  }
}
