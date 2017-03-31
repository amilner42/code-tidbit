/// Module for encapsaluting all routes for the API. Any complex logic in here
/// should be moved to a seperate module.

import passport from 'passport';
import * as R from "ramda";

import { completedDBActions } from "./models/completed.model";
import { Content, contentDBActions } from "./models/content.model";
import { User, userDBActions, prepareUserForResponse } from './models/user.model';
import { Snipbit, snipbitDBActions } from './models/snipbit.model';
import { Bigbit, bigbitDBActions } from './models/bigbit.model';
import { Story, NewStory, ExpandedStory, storyDBActions } from "./models/story.model";
import { Tidbit, tidbitDBActions } from './models/tidbit.model';
import { AppRoutes, AppRoutesAuth, FrontendError, TargetID, ErrorCode, BasicResponse } from './types';
import { internalError, combineArrays } from './util';


/**
 * A dictionary matching the same format as `routes` that specifies whether
 * routes do not require authentication. By default, all routes require
 * authentication.
 */
export const authlessRoutes: AppRoutesAuth = {
  '/register': { post: true },
  '/login': { post: true },
  '/snipbits': { get: true },
  '/snipbits/:id': { get: true },
  '/bigbits/': { get: true },
  '/bigbits/:id': { get: true },
  '/stories': { get: true },
  '/stories/:id': { get: true },
  '/tidbits': { get: true },
  '/content': { get: true }
};

/**
 * The routes for the API.
 */
export const routes: AppRoutes = {

  '/register': {
    /**
     * Register a user for the application, requires a username and password.
     */
    post: (req, res, next): Promise<User> => {

      return new Promise<User>((resolve, reject) => {

        passport.authenticate('sign-up', (err, user, info) => {
          // A 500-like error.
          if(err) {
            reject(internalError("There was an internal error signing-up (phase-1)"));
            return;
          }

          // If no user an error must have occured.
          if(!user) {
            reject({ errorCode: info.errorCode, message: info.message });
            return;
          }

          // Log user in.
          req.login(user, (err) => {
            if(err) {
              reject(internalError("There was an internal error signing-up (phase-2)"));
              return;
            }

            resolve(prepareUserForResponse(user));
          });
        })(req, res, next);
      });
    }
  },

  '/login': {
    /**
     * Logs a user in and returns the user or a standard error + code.
     */
    post: (req, res, next): Promise<User> => {

      return new Promise<User>((resolve, reject) => {

        passport.authenticate('login', (err, user, info) => {
          // A 500-like error
          if (err) {
            reject(internalError("There was an internal error logging-in (phase 1)"));
            return;
          }

          // If no user an error must have occured.
          if (!user) {
            reject({ message: info.message, errorCode: info.errorCode });
            return;
          }

          // Log user in.
          req.login(user, (err) => {
            if (err) {
              reject(internalError("There was an internal error logging-in (phase 2)"));
              return;
            }

            resolve(prepareUserForResponse(user));
          });
        })(req, res, next);
      });
    }
  },

  '/logOut': {
    /**
     * Logs the user out and clears the session cookie.
     */
    get: (req, res): Promise<BasicResponse> => {

      return new Promise<BasicResponse>((resolve, reject) => {
        // req.logout();
        // http://stackoverflow.com/questions/13758207/why-is-passportjs-in-node-not-removing-session-on-logout
        req.session.destroy(function (err) {
          if(err) {
            reject(internalError("Error removing session"));
            return;
          }
          res.clearCookie('connect.sid');
          resolve({ message: "Successfully logged out" });
        });
      });
    }
  },

  '/account': {
    /**
     * Returns the users account with sensitive data stripped.
     */
    get: (req, res, next): Promise<User> => {
      return Promise.resolve(prepareUserForResponse(req.user));
    },

    /**
     * Updates the user and returns the new updated user.
     */
    post: (req, res): Promise<User> => {
      const userUpdateObject = req.body;
      const userID = req.user._id;

      return userDBActions.updateUser(userID, userUpdateObject);
    }
  },

  '/account/addCompleted': {
    /**
     * Adds the tidbit as completed for the logged-in user, if it's already
     * completed no changes are made.
     */
    post: (req, res): Promise<TargetID> => {
      const userID = req.user._id;
      const completed = req.body;

      return completedDBActions.addCompleted(completed, userID);
    }
  },

  '/account/removeCompleted': {
    /**
     * Removes the tidbit from the completed table for the logged-in user, no
     * changes are made if the tidbit wasn't in the completed table to begin
     * with.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const completed = req.body;

      return completedDBActions.removeCompleted(completed, userID);
    }
  },

  '/account/checkCompleted': {
    /**
     * Checks if a tidbit is completed for the logged-in user.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const completed = req.body;

      return completedDBActions.isCompleted(completed, userID);
    }
  },

  '/snipbits': {
    /**
     * Gets snipbits, customizable through query params.
     */
    get: (req, res): Promise<Snipbit[]> => {
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return snipbitDBActions.getSnipbits(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    },

    /**
     * Creates a new snipbit for the logged-in user.
     */
    post: (req, res): Promise<TargetID> => {
      const userID = req.user._id;
      const snipbit = req.body;

      return snipbitDBActions.addNewSnipbit(userID, snipbit);
    }
  },

  '/bigbits': {
    /**
     * Gets bigbits, customizable through query params.
     */
    get: (req, res): Promise<Bigbit[]> => {
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return bigbitDBActions.getBigbits(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    },

    /**
     * Creates a new snipbit for the logged-in user.
     */
    post: (req, res): Promise<TargetID> => {
      const userID = req.user._id;
      const bigbit = req.body;

      return bigbitDBActions.addNewBigbit(userID, bigbit);
    }
  },

  '/snipbits/:id': {
    /**
     * Gets a snipbit.
     */
    get: (req, res): Promise<Snipbit> => {
      const params = req.params;
      const snipbitID = params["id"];

      return snipbitDBActions.getSnipbit(snipbitID);
    }
  },

  '/bigbits/:id': {
    /**
     * Gets a bigbit.
     */
    get: (req, res): Promise<Bigbit> => {
      const params = req.params;
      const bigbitID = params["id"];

      return bigbitDBActions.getBigbit(bigbitID);
    }
  },

  '/stories': {

    /**
     * Get's stories, can customize query through query-params.
     */
    get: (req, res): Promise<Story[]> => {
      const userID = req.user._id;
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return storyDBActions.getStories(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    },

    /**
     * For creating a new story for the given user.
     */
    post: (req, res): Promise<TargetID> => {
      const newStory: NewStory  = req.body;
      const userID = req.user._id;

      return storyDBActions.createNewStory(userID, newStory);
    }
  },

  '/stories/:id': {
    /**
     * Gets a story from the db, customizable through query params.
     */
    get: (req, res): Promise<Story | ExpandedStory> => {
      const params = req.params;
      const storyID = params.id;
      const queryParams = req.query;
      const expandStory = !!queryParams.expandStory;
      const withCompleted = !!queryParams.withCompleted;
      const userID = req.user ? req.user._id : null;

      return storyDBActions.getStory(storyID, expandStory, withCompleted ? userID : null );
    }
  },

  '/stories/:id/information': {
    /**
     * Updates the basic information connected to a story.
     */
    post: (req, res): Promise<TargetID> => {
      const params = req.params;
      const storyID = params.id;
      const userID = req.user._id;
      const editedInfo = req.body;

      return storyDBActions.updateStoryInfo(userID, storyID, editedInfo);
    }
  },

  '/stories/:id/addTidbits': {
    /**
     * Adds tidbits to an existing story.
     */
    post: (req, res): Promise<ExpandedStory> => {
      const params = req.params;
      const storyID = params.id;
      const userID = req.user._id;
      const newStoryTidbitPointers = req.body;

      return storyDBActions.addTidbitPointersToStory(userID, storyID, newStoryTidbitPointers);
    }
  },

  '/tidbits': {
    /**
     * Gets all the tidbits, customizable through query params.
     */
    get: (req, res): Promise<Tidbit[]> => {
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return tidbitDBActions.getTidbits(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    }
  },

  '/content': {
    /**
     * Get's `Content` (for the browse page), customizable through query params.
     */
    get: (req, res): Promise<Content[]> => {
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return contentDBActions.getContent(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    }
  }
}

/**
 * Get's `sortByLastModified` from query params as a boolean.
 */
const getSortByLastModifiedAsBoolean = ({ sortByLastModified }): boolean => sortByLastModified === "true";

/**
 * Get's `sortByTextScore` from query params as a boolean.
 */
const getSortByTextScoreAsBoolean = ({ sortByTextScore }): boolean => sortByTextScore === "true";

/**
 * Get's `pageNumber` from query params as an int.
 */
const getPageNumberAsInt = ({ pageNumber }): number => parseInt(pageNumber);

/**
 * Get's `pageSize` from query params as an int.
 */
const getPageSizeAsInt = ({ pageSize }): number => parseInt(pageSize);

/**
 * Get's `author` as a string.
 */
const getAuthorAsString = ({ author }): string => author;

/**
 * Get's the `searchQuery` as a string.
 */
const getSearchQueryAsString = ({ searchQuery }): string => searchQuery;

/**
 * For staying DRY while extracting `ContentResultManipulation` from query parameters.
 */
const getContentResultManipulationFromQP = ( queryParams ) => {
  return {
    sortByLastModified: getSortByLastModifiedAsBoolean(queryParams),
    sortByTextScore: getSortByTextScoreAsBoolean(queryParams),
    pageNumber: getPageNumberAsInt(queryParams),
    pageSize: getPageSizeAsInt(queryParams)
  }
}

/**
 * For staying DRY while extracting `ContentSearchFilter` from query parameters.
 */
const getContentSearchFilterFromQP = ( queryParams ) => {
  return {
    author: getAuthorAsString(queryParams),
    searchQuery: getSearchQueryAsString(queryParams)
  }
}

/**
 * Metadata the backend uses such as `textScore` need to be stripped prior to sending to the frontend.
 */
const removeMetadataForResponse = (obj) => {
  delete obj.textScore;
  return obj;
}
