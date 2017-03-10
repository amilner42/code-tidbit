/// Module for encapsaluting all routes for the API. Any complex logic in here
/// should be moved to a seperate module.

import { Response } from "express";
import * as kleen from "kleen";
import passport from 'passport';

import { completedDBActions } from "./models/completed.model";
import { User, userDBActions, prepareUserForResponse } from './models/user.model';
import { Snipbit, snipbitDBActions } from './models/snipbit.model';
import { Bigbit, bigbitDBActions } from './models/bigbit.model';
import { NewStory, storyDBActions } from "./models/story.model";
import { tidbitDBActions } from './models/tidbit.model';
import { AppRoutes, AppRoutesAuth, FrontendError } from './types';
import { internalError } from './util';


/**
 * Returns true if the current user has the given `id`.
 */
export const isUser = (req, id) => {
  return req.user._id === id;
};

/**
 * Use in catch-blocks (eg. `.catch(handleError(res))`) to check and then send
 * outgoing errors. Will make sure all outgoing errors have the `FrontendError`
 * format.
 */
export const handleError = (res: Response): ((error: FrontendError) => Promise<void>) => {
  // Kleen schema for a FrontendError.
  const frontendErrorScheme: kleen.typeSchema = {
    objectProperties: {
        "errorCode": {
            primitiveType: kleen.kindOfPrimitive.number
        },
        "message": {
            primitiveType: kleen.kindOfPrimitive.string
        },
    }
  };

  return (error) => {
    return kleen.validModel(frontendErrorScheme)(error)
    .then(() => {
      res.status(400).json(error);
    })
    .catch(() => {
      console.log("[LOG] Unknown error: " + error);

      res.status(400).json(
        internalError("An unknown internal error occured...")
      );
    });
  };
};

/**
 * Sends the success object back to the server with a 200 status.
 */
export const handleSuccess =  (res: Response): ((successObj) => void) => {
  return (successObj) => {
    res.status(200).json(successObj);
  }
};

/**
 * Handles an action where we want to send the result object back to the server
 * directly upon success and we want to send a proper error message back to the
 * server upon failure.
 */
export const handleAction = <successObj>(res: Response): ((action: Promise<successObj>) => Promise<void>) => {
  return (action) => {
    return action.then(handleSuccess(res)).catch(handleError(res));
  }
};

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
  '/tidbits': { get: true }
};

/**
 * The routes for the API.
 */
export const routes: AppRoutes = {

  '/register': {
    /**
     * Register a user for the application, requires a username and password.
     */
    post: (req, res, next) => {

      passport.authenticate('sign-up', (err, user, info) => {
        // A 500-like error.
        if(err) {
          next(err);
          return;
        }

        // If no user an error must have occured.
        if(!user) {
          res.status(400).json(
            { message: info.message, errorCode: info.errorCode }
          );
          return;
        }

        // Log user in.
        req.login(user, (err) => {
          if(err) {
            next(err);
            return;
          }

          res.status(201).json(prepareUserForResponse(user));
          return;
        });
      })(req, res, next);
    }
  },

  '/login': {
    /**
     * Logs a user in and returns the user or a standard error + code.
     */
    post: (req, res, next) => {
      passport.authenticate('login', (err, user, info) => {
        // A 500-like error
        if (err) {
          next(err);
          return;
        }

        // If no user an error must have occured.
        if (!user) {
          res.status(400).json(
            { message: info.message, errorCode: info.errorCode }
          );
          return;
        }

        // Log user in.
        req.login(user, (err) => {
          if (err) {
            return next(err);
          }

          res.status(200).json(prepareUserForResponse(user));
          return;
        });
      })(req, res, next);
    }
  },

  '/logOut': {
    /**
     * Logs the user out and clears the session cookie.
     */
    get: (req, res) => {
      // req.logout();
      // http://stackoverflow.com/questions/13758207/why-is-passportjs-in-node-not-removing-session-on-logout
      req.session.destroy(function (err) {
        if(err) {
          console.log("Err removing session, ", err);
        }
        res.clearCookie('connect.sid');
        res.status(200).json({message: "Successfully logged out"});
        return;
      });
    }
  },

  '/account': {
    /**
     * Returns the users account with sensitive data stripped.
     */
    get: (req, res, next) => {
      res.status(200).json(prepareUserForResponse(req.user));
      return;
    },

    /**
     * Updates the user and returns the new updated user.
     */
    post: (req, res) => {
      const userUpdateObject = req.body;
      const userID = req.user._id;

      handleAction(res)(userDBActions.updateUser(userID, userUpdateObject));
    }
  },

  '/account/addCompleted': {
    /**
     * Adds the tidbit as completed for the logged-in user, if it's already
     * completed no changes are made.
     */
    post: (req, res) => {
      const userID = req.user._id;
      const completed = req.body;

      handleAction(res)(completedDBActions.markAsComplete(completed, userID));
    }
  },

  '/account/removeCompleted': {
    /**
     * Removes the tidbit from the completed table for the logged-in user, no
     * changes are made if the tidbit wasn't in the completed table to begin
     * with.
     */
    post: (req, res) => {
      const userID = req.user._id;
      const completed = req.body;

      handleAction(res)(completedDBActions.markAsIncomplete(completed, userID));
    }
  },

  '/account/checkCompleted': {
    /**
     * Checks if a tidbit is completed for the logged-in user.
     */
    post: (req, res) => {
      const userID = req.user._id;
      const completed = req.body;

      handleAction(res)(completedDBActions.isCompleted(completed, userID));
    }
  },

  '/snipbits': {
    /**
     * Gets snipbits, customizable through query params.
     */
    get: (req, res) => {
      const queryParams = req.query;
      const forUser = queryParams.forUser;

      handleAction(res)(snipbitDBActions.getSnipbits({ forUser }));
    },

    /**
     * Creates a new snipbit for the logged-in user.
     */
    post: (req, res) => {
      const userID = req.user._id;
      const snipbit = req.body;

      handleAction(res)(snipbitDBActions.addNewSnipbit(userID, snipbit));
    }
  },

  '/bigbits': {
    /**
     * Gets bigbits, customizable through query params.
     */
    get: (req, res) => {
      const queryParams = req.query;
      const forUser = queryParams.forUser;

      handleAction(res)(bigbitDBActions.getBigbits({ forUser }));
    },

    /**
     * Creates a new snipbit for the logged-in user.
     */
    post: (req, res) => {
      const userID = req.user._id;
      const bigbit = req.body;

      handleAction(res)(bigbitDBActions.addNewBigbit(userID, bigbit));
    }
  },

  '/snipbits/:id': {
    /**
     * Gets a snipbit.
     */
    get: (req, res) => {
      const params = req.params;
      const snipbitID = params["id"];

      handleAction(res)(snipbitDBActions.getSnipbit(snipbitID));
    }
  },

  '/bigbits/:id': {
    /**
     * Gets a bigbit.
     */
    get: (req, res) => {
      const params = req.params;
      const bigbitID = params["id"];

      handleAction(res)(bigbitDBActions.getBigbit(bigbitID));
    }
  },

  '/stories': {

    /**
     * Get's stories, can customize query through query-params.
     */
    get: (req, res) => {
      const userID = req.user._id;
      const queryParams = req.query;
      const author = queryParams.author;

      handleAction(res)(storyDBActions.getStories({ author }));
    },

    /**
     * For creating a new story for the given user.
     */
    post: (req, res) => {
      const newStory: NewStory  = req.body;
      const userID = req.user._id;

      handleAction(res)(storyDBActions.createNewStory(userID, newStory));
    }
  },

  '/stories/:id': {
    /**
     * Gets a story from the db, customizable through query params.
     */
    get: (req, res) => {
      const params = req.params;
      const storyID = params.id;
      const queryParams = req.query;
      const expandStory = !!queryParams.expandStory;
      const withCompleted = !!queryParams.withCompleted;
      const userID = req.user ? req.user._id : null;

      handleAction(res)(storyDBActions.getStory(storyID, expandStory, withCompleted ? userID : null ));
    }
  },

  '/stories/:id/information': {
    /**
     * Updates the basic information connected to a story.
     */
    post: (req, res) => {
      const params = req.params;
      const storyID = params.id;
      const userID = req.user._id;
      const editedInfo = req.body;

      handleAction(res)(storyDBActions.updateStoryInfo(userID, storyID, editedInfo));
    }
  },

  '/stories/:id/addTidbits': {
    /**
     * Adds tidbits to an existing story.
     */
    post: (req, res) => {
      const params = req.params;
      const storyID = params.id;
      const userID = req.user._id;
      const newStoryTidbitPointers = req.body;

      handleAction(res)(storyDBActions.addTidbitPointersToStory(userID, storyID, newStoryTidbitPointers));
    }
  },

  '/tidbits': {
    /**
     * Gets all the tidbits, customizable through query params.
     */
    get: (req, res) => {
      const queryParams = req.query;
      const forUser = queryParams.forUser;

      handleAction(res)(tidbitDBActions.getTidbits({ forUser }));
    }
  }
}
