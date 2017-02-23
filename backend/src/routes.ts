/// Module for encapsaluting all routes for the API. Any complex logic in here
/// should be moved to a seperate module.

import { Response } from "express";
import * as kleen from "kleen";
import passport from 'passport';

import { APP_CONFIG } from '../app-config';
import { User, userModel } from './models/user.model';
import { Snipbit, validifyAndUpdateSnipbit } from './models/snipbit.model';
import { validifyAndUpdateBigbit, Bigbit } from './models/bigbit.model';
import { swapPeriodsWithStars, metaMap } from './models/file-structure.model';
import { AppRoutes, AppRoutesAuth, ErrorCode, FrontendError, Language } from './types';
import { collection, ID } from './db';
import { internalError, asyncIdentity } from './util';


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
 * A dictionary matching the same format as `routes` that specifies whether
 * routes do not require authentication. By default, all routes require
 * authentication.
 */
export const authlessRoutes: AppRoutesAuth = {
  '/register': { post: true },
  '/login': { post: true },
  '/snipbits/:id': { get: true },
  '/bigbits/:id': { get: true }
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

  '/snipbits': {
    /**
     * Creates a new snipbit for the logged-in user.
     */
    post: (req, res) => {
      const user: User = req.user;
      const snipbit = req.body;

      validifyAndUpdateSnipbit(snipbit)
      .then((updatedSnipbit: Snipbit) => {
        updatedSnipbit.author = user._id;

        return collection("snipbits")
        .then((snipbitCollection) => {
          return snipbitCollection.insertOne(updatedSnipbit);
        })
        .then((snipbit) => {
          res.status(200).json({ newID: snipbit.insertedId });
          return;
        });
      })
      .catch(handleError(res));
    }
  },

  '/bigbits': {
    /**
     * Creates a new snipbit for the logged-in user.
     */
    post: (req, res) => {
      const user: User = req.user;
      const bigbit = req.body;

      validifyAndUpdateBigbit(bigbit)
      .then((updatedBigbit: Bigbit) => {
        updatedBigbit.author = user._id;

        return collection("bigbits")
        .then((bigbitCollection) => {
          return bigbitCollection.insertOne(updatedBigbit);
        })
        .then((bigbit) => {
          res.status(200).json({ newID: bigbit.insertedId })
          return;
        });
      })
      .catch(handleError(res));
    }
  },

  '/snipbits/:id': {
    /**
     * Gets a snipbit.
     */
     get: (req, res) => {
      const params = req.params;
      const snipbitID = params["id"];

      collection("snipbits")
      .then((snipbitCollection) => {
        return snipbitCollection.findOne({ _id: ID(snipbitID)}) as Promise<Snipbit>;
      })
      .then((snipbit) => {

        if(!snipbit) {
          res.status(400).json({
            errorCode: ErrorCode.snipbitDoesNotExist,
            message: `ID ${snipbitID} does not point to a snipbit.`
          });
          return;
        }

        // Rename `_id` field.
        snipbit.id = snipbit._id;
        delete snipbit._id;

        // Update `language` to encoded language name.
        return collection("languages")
        .then((languageCollection) => {
          return languageCollection.findOne({ _id: snipbit.language }) as Promise<Language>;
        })
        .then((language) => {

          if(!language) {
            res.status(400).json({
              errorCode: ErrorCode.internalError,
              message: `Language ID ${snipbit.language} was invalid`
            });
          }

          // Update language to encoded language name.
          snipbit.language = language.encodedName;
          res.status(200).json(snipbit);
        });
      })
      .catch(handleError(res));
     }
  },

  '/bigbits/:id': {
    /**
     * Gets a bigbit.
     */
    get: (req, res) => {
      const params = req.params;
      const bigbitID = params["id"];

      collection("bigbits")
      .then((bigbitCollection) => {
        return bigbitCollection.findOne({ _id: ID(bigbitID) }) as Promise<Bigbit>;
      })
      .then((bigbit) => {

        if(!bigbit) {
          res.status(400).json({
            errorCode: ErrorCode.bigbitDoesNotExist,
            message: `ID ${bigbitID} does not point to a bigbit.`
          });
          return;
        }

        // Rename id field.
        bigbit.id = bigbit._id;
        delete bigbit._id;

        return collection("languages")
        .then((languageCollection) => {
          // Swap all languageIDs with encoded language names.
          return metaMap(
            asyncIdentity,
            asyncIdentity,
            (fileMetadata => {
              return new Promise<{language: string}>((resolve, reject) => {
                languageCollection.findOne({ _id: ID(fileMetadata.language) })
                .then((language: Language) => {
                  if(!language) {
                    reject({
                      errorCode: ErrorCode.internalError,
                      message: `Language ID ${fileMetadata.language} does not point to a language`
                    });
                    return;
                  }

                  resolve({ language: language.encodedName });
                  return;
                });
              });
            }),
            bigbit.fs
          );
        })
        .then((updatedFS) => {
          // Switch to updated fs, which includes swapping '*' with '.'
          bigbit.fs = swapPeriodsWithStars(false, updatedFS);
          res.status(200).json(bigbit);
          return;
        });
      })
      .catch(handleError(res));
    }
  }
}
