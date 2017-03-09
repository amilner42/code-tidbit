/// Module for interacting with the mongodb through the standard node driver.
/// Will get the URL for the mongodb from the global config `app-config.ts`.

import { MongoClient, Collection, ObjectID } from 'mongodb';

import { APP_CONFIG } from '../app-config';
import { MongoID } from './types';


/**
 * Promise will resolve to the db.
 */
const DB_PROMISE = MongoClient.connect(APP_CONFIG.db.url);

/**
 * Get a mongodb collection with no wrappers other than the driver itself.
 *
 * @param collectionName Name of the collection.
 * @returns Promise to the collection
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
 * Get the ObjectID from an ID, basic convenience method.
 *
 * @param idString The id as a string / objectID
 * @returns A new mongo ObjectID object with idString as the ID
 */
export const ID = (idString: string | ObjectID): ObjectID => {
  // If it's an objectID, it'll just be returned (the typings are wrong).
  // https://github.com/mongodb/js-bson/blob/9e4b56bd9681539896f7633f6de0771b7185927b/lib/bson/objectid.js#L30
  return new ObjectID(idString as string);
}

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
export const sameID = (id1: MongoID, id2: MongoID) => {
  return ID(id1).equals(ID(id2));
}
