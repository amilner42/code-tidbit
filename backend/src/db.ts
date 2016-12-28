/// Module for interacting with the mongodb through the standard node driver.
/// Will get the URL for the mongodb from the global config `app-config.ts`.

import { MongoClient, Collection, ObjectID } from 'mongodb';

import { APP_CONFIG } from '../app-config';


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
 * @param idString The id as a string
 * @returns A new mongo ObjectID object with idString as the ID
 */
export const ID = (idString: string): ObjectID => {
  return new ObjectID(idString);
}
