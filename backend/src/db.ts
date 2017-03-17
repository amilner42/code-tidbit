/// Module for interacting with the mongodb through the standard node driver.
/// Will get the URL for the mongodb from the global config `app-config.ts`.

import { MongoClient, Collection, ObjectID } from 'mongodb';

import { APP_CONFIG } from '../app-config';
import { isNullOrUndefined } from './util';
import { MongoID, MongoObjectID, MongoStringID } from './types';


/**
 * Promise will resolve to the db.
 */
const DB_PROMISE = MongoClient.connect(APP_CONFIG.db.url);

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
