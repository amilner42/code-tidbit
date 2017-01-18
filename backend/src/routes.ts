/// Module for encapsaluting all routes for the API. Any complex logic in here
/// should be moved to a seperate module.

import { Response } from "express";
import * as kleen from "kleen";
import passport from 'passport';
import R from 'ramda';

import { APP_CONFIG } from '../app-config';
import { User, userModel } from './models/user.model';
import { BasicTidbit, validifyAndUpdateBasicTidbit } from './models/basic-tidbit.model';
import { AppRoutes, ErrorCode, FrontendError } from './types';
import { collection } from './db';
import { internalError } from './util';


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
 * All routes by default will be assumed to require authentication, routes that
 * do not must be listed below. The API base url need not be included in the
 * array as it is `map`ed on.
 */
export const apiAuthlessRoutes = [
  '/register',
  '/login'
].map((route) => `${APP_CONFIG.app.apiSuffix}${route}`);

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

          res.status(201).json(userModel.stripSensitiveDataForResponse(user));
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

          res.status(200).json(userModel.stripSensitiveDataForResponse(user));
          return;
        });
      })(req, res, next);
    }
  },

  '/account': {
    /**
     * Returns the users account with sensitive data stripped.
     */
    get: (req, res, next) => {
      res.status(200).json(userModel.stripSensitiveDataForResponse(req.user));
      return;
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

  '/create/basicTidbit': {
    /**
     * Creates a new basic tidbit for a user.
     */
    post: (req, res) => {
      const user: User = req.user;
      const basicTidbit = req.body;

      validifyAndUpdateBasicTidbit(basicTidbit)
      .then((updatedBasicTidbit: BasicTidbit) => {
        updatedBasicTidbit.author = user._id;

        collection("basicTidbits")
        .then((basicTidbitCollection) => {
          return basicTidbitCollection.save(updatedBasicTidbit);
        })
        .then(() => {
          res.status(200).json({ message: "Tidbit created successfully."});
          return;
        });
      })
      .catch(handleError(res));
    }
  }
}
