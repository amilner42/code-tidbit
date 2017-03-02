/// Module for encapsaluting all routes for the API. Any complex logic in here
/// should be moved to a seperate module.

import { Response } from "express";
import * as kleen from "kleen";
import passport from 'passport';

import { APP_CONFIG } from '../app-config';
import { User, updateUserSchema, UserUpdateObject, prepareUserForResponse } from './models/user.model';
import { Snipbit, validifyAndUpdateSnipbit } from './models/snipbit.model';
import { validifyAndUpdateBigbit, Bigbit } from './models/bigbit.model';
import { swapPeriodsWithStars, metaMap } from './models/file-structure.model';
import { Story, prepareStoryForResponse, newStorySchema } from "./models/story.model";
import { AppRoutes, AppRoutesAuth, ErrorCode, FrontendError, Language } from './types';
import { ObjectID } from "mongodb";
import { collection, ID, renameIDField } from './db';
import { internalError, asyncIdentity, dropNullAndUndefinedProperties, isNullOrUndefined } from './util';


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
 * A dictionary matching the same format as `routes` that specifies whether
 * routes do not require authentication. By default, all routes require
 * authentication.
 */
export const authlessRoutes: AppRoutesAuth = {
  '/register': { post: true },
  '/login': { post: true },
  '/snipbits/:id': { get: true },
  '/bigbits/:id': { get: true },
  '/stories': { get: true },
  '/stories/:id': { get: true }
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
      const userUpdateObject: UserUpdateObject = req.body;
      const userID = req.user._id;

      kleen.validModel(updateUserSchema)(userUpdateObject)
      .then(() => {
        return collection("users");
      })
      .then((UserCollection) => {
        return UserCollection.findOneAndUpdate(
          { _id: ID(userID) },
          { $set: dropNullAndUndefinedProperties(userUpdateObject) },
          { returnOriginal: false}
        );
      })
      .then((updatedUserResult) => {
        if(updatedUserResult.value) {
          res.status(200).json(prepareUserForResponse(updatedUserResult.value));
          return;
        }

        res.status(400).json({
          errorCode: ErrorCode.internalError,
          message: "We couldn't find your account."
        })
        return;
      })
      .catch(handleError(res));
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
          res.status(200).json({ targetID: snipbit.insertedId });
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
          res.status(200).json({ targetID: bigbit.insertedId })
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

        renameIDField(snipbit);

        // Update `language` to encoded language name.
        return collection("languages")
        .then((languageCollection) => {
          return languageCollection.findOne({ _id: ID(snipbit.language) }) as Promise<Language>;
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

        renameIDField(bigbit);

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
  },

  '/stories': {

    /**
     * Get's stories, can customize query through query-params.
     */
    get: (req, res) => {
      const userID = req.user._id;
      const queryParams = req.query;
      const author = queryParams.author;

      collection("stories")
      .then((StoryCollection) => {
        const mongoSearchFilter: { author?: ObjectID } = {};

        if(!isNullOrUndefined(author)) {
          mongoSearchFilter.author = ID(author);
        }

        return StoryCollection.find(mongoSearchFilter).toArray();
      })
      .then((stories) => {
        res.status(200).json(stories.map(prepareStoryForResponse));
        return;
      })
      .catch(handleError(res));
    },

    /**
     * For creating a new story for the given user.
     */
    post: (req, res) => {
      const story: Story  = req.body;
      const userID = req.user._id;

      kleen.validModel(newStorySchema)(story)
      .then(() => {
        return collection("stories");
      })
      .then((StoryCollection) => {
        // DB-added fields here:
        //  - Author
        //  - Add blank pages.
        story.author = userID;
        story.pages = [];
        return StoryCollection.insertOne(story);
      })
      .then((story) => {
        res.status(200).json({ targetID: story.insertedId });
        return;
      })
      .catch(handleError(res));
    }
  },

  '/stories/:id': {
    /**
     * Gets a story from the db.
     */
    get: (req, res) => {
      const params = req.params;
      const storyID = params.id;

      collection('stories')
      .then((storyCollection) => {
        return storyCollection.findOne({ _id: ID(storyID) }) as Promise<Story>;
      })
      .then((story) => {
        if(!story) {
          res.status(400).json({
            message: `No story exists with id: ${storyID}`,
            errorCode: ErrorCode.storyDoesNotExist
          });
          return
        }

        res.status(200).json(prepareStoryForResponse(story));
        return;
      })
      .catch(handleError(res));
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

      kleen.validModel(newStorySchema)(editedInfo)
      .then(() => {
        return collection('stories')
      })
      .then((storyCollection) => {
        return storyCollection.findOneAndUpdate(
          { _id: ID(storyID),
            author: userID
          },
          { $set: editedInfo },
          {}
        );
      })
      .then((updateStoryResult) => {
        if(updateStoryResult.value) {
          res.status(200).json({ targetID: updateStoryResult.value._id });
          return;
        }

        res.status(400).json({
          errorCode: ErrorCode.internalError,
          message: "You do not have a story with that ID."
        });
        return;
      })
      .catch(handleError(res));
    }
  }
}
