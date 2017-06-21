/// Module for interacting with the mongodb through the standard node driver.
/// Will get the URL for the mongodb from the global config `app-config.ts`.

import { MongoClient, Collection, ObjectID, Cursor, UpdateWriteOpResult } from 'mongodb';
import * as R from "ramda";

import { APP_CONFIG } from './app-config';
import { isNullOrUndefined, internalError } from './util';
import { MongoID, MongoObjectID, MongoStringID } from './types';


/**
 * Promise will resolve to the db.
 */
const DB_PROMISE = MongoClient.connect(APP_CONFIG.dbUrl);

/**
 * The max page size that can be queried at once.
 */
const MAX_PAGE_SIZE = 50;

/**
 * Get a mongodb collection using the existing mongo connection.
 */
export const collection = (collectionName: string): Promise<Collection> => {
  return new Promise((resolve, reject) => {
    DB_PROMISE
    .then((db) => {
      resolve(db.collection(collectionName));
      return;
    })
    .catch((error) => {
      reject(error);
      return;
    })
  });
}

/**
 * Forces a `MongoID` into a strict state of being a `MongoObjectID`.
 */
export const toMongoObjectID = (mongoID: MongoID): MongoObjectID => {

  // Null/Undefined gaurd.
  if(isNullOrUndefined(mongoID)) { return null; }

  // If it's an objectID, it'll just be returned (the typings are wrong).
  // https://github.com/mongodb/js-bson/blob/9e4b56bd9681539896f7633f6de0771b7185927b/lib/bson/objectid.js#L30
  return new ObjectID(mongoID as string);
};

/**
 * Forces a `MongoID` into a strict state of being a `MongoStringID`.
 */
export const toMongoStringID = (mongoID: MongoID): MongoStringID => {

  // Null/Undefined gaurd.
  if(isNullOrUndefined(mongoID)) { return null; }

  return toMongoObjectID(mongoID).toHexString();
};

/**
 * Renames the `_id` field to `id` if it has an `_id` field.
 *
 * @WARNING Mutates `obj`.
 */
export const renameIDField = (obj) => {
  if(obj._id) {
    obj.id = obj._id;
    delete obj._id;
  }

  return obj;
}

/**
 * Checks that two IDs are the same, regardless of if they are in string-form or
 * ObjectID-form.
 */
export const sameID = (id1: MongoID, id2: MongoID): boolean => {
  return toMongoObjectID(id1).equals(toMongoObjectID(id2));
}

/**
 * Paginates results, assumes the results are already in some meaningful order - this just handles the `limit` and
 * `skip` to get the proper chunk of results. Also will ensure `MAX_PAGE_SIZE`.
 *
 * @RETURNS A pair: [ Boolean that is `true` if there is MORE data, the results ]
 */
export const getPaginatedResults = (pageNumber: number, pageSize: number, cursor: Cursor): PromiseLike<[boolean, any[]]> => {
  pageSize = Math.min(pageSize, MAX_PAGE_SIZE);
  const amountToSkip = (pageNumber - 1) * pageSize;

  return cursor.skip(amountToSkip).limit(pageSize + 1).toArray()
  .then((results) => {
    if(results.length == (pageSize + 1)) {
      return [true, R.dropLast(1, results) ]
    }

    return [false, results ];
  });
}

/**
 * Mongo can resolve even though an error occured, to avoid this behaviour we reject if the result is not ok.
 *
 * Returns the original `result` if it's ok so this can easily be added to promise chains.
 *
 * @refer: http://mongodb.github.io/node-mongodb-native/2.1/api/Collection.html#~updateWriteOpResult
 */
export const rejectIfResultNotOK = (result: UpdateWriteOpResult): Promise<UpdateWriteOpResult> => {
  if(result.result.ok !== 1) return Promise.reject(internalError(`Mongo query not ok: ${result.result.ok}`));

  return Promise.resolve(result);
};

/**
 * If no modifications were made rejects with an internal error, otherwise returns the original `result`.
 */
export const rejectIfNoneModified = (result: UpdateWriteOpResult): Promise<UpdateWriteOpResult> => {
  if (result.modifiedCount === 0) return Promise.reject(internalError("No modifications were performed"));

  return Promise.resolve(result);
};

/**
 * If no documents were matched rejects with an internal error, otherwise returns the original result.
 */
export const rejectIfNoneMatched = (result: UpdateWriteOpResult): Promise<UpdateWriteOpResult> => {
  if(result.matchedCount === 0) return Promise.reject(internalError("No matching documents were found"));

  return Promise.resolve(result);
};

/**
 * If no documents were upserted, rejects with an internal error, otherwise returns the original result.
 */
export const rejectIfNoneUpserted = (result: UpdateWriteOpResult): Promise<UpdateWriteOpResult> => {
  if(result.upsertedCount === 0) return Promise.reject(internalError("No upserts were performed"));

  return Promise.resolve(result);
};
