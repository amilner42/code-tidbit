/// Module for encapsaluting all routes for the API. Any complex logic in here
/// should be moved to a seperate module.

import passport from 'passport';
import * as R from "ramda";

import { toMongoObjectID  } from "./db";
import { opinionDBActions, Rating, Ratings } from "./models/opinion.model";
import { completedDBActions } from "./models/completed.model";
import { Content, contentDBActions, ContentSearchFilter, GeneralSearchConfiguration, ContentResultManipulation, ContentPointer, ContentType } from "./models/content.model";
import { User, userDBActions, prepareUserForResponse } from './models/user.model';
import { Snipbit, snipbitDBActions } from './models/snipbit.model';
import { Bigbit, bigbitDBActions } from './models/bigbit.model';
import { Story, NewStory, ExpandedStory, storyDBActions, StorySearchFilter } from "./models/story.model";
import { Tidbit, tidbitDBActions } from './models/tidbit.model';
import { QA, qaDBActions } from "./models/qa.model";
import { AppRoutes, AppRoutesAuth, FrontendError, TargetID, ErrorCode, BasicResponse, MongoID } from './types';
import { internalError, combineArrays, maybeMap } from './util';


/**
 * A dictionary matching the same format as `routes` that specifies whether
 * routes do not require authentication. By default, all routes require
 * authentication.
 */
export const authlessRoutes: AppRoutesAuth = {
  '/register': { post: true },
  '/login': { post: true },
  '/userID/:email': { get: true },
  '/snipbits': { get: true },
  '/snipbits/:id': { get: true },
  '/bigbits/': { get: true },
  '/bigbits/:id': { get: true },
  '/stories': { get: true },
  '/stories/:id': { get: true },
  '/tidbits': { get: true },
  '/content': { get: true },
  '/opinions/:contentType/:contentID': { get: true },
  '/qa/:tidbitType/:tidbitID': { get: true }
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

  '/userID/:email': {
    /**
     * Retrieves the id of the user with the given email, returns `null` if the user doesn't exist.
     */
    get: (req, res): Promise<MongoID> => {
      const params = req.params;
      const email = params.email;

      return userDBActions.getUserID(email);
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

  '/account/getOpinion/:contentType/:contentID': {
    /**
     * Get's a user's opinion on specific content.
     */
    get: (req, res): Promise<Rating> => {
      const { contentType, contentID } = req.params;
      const userID = req.user._id;
      const contentPointer = {
        contentType: parseInt(contentType),
        contentID
      };

      return opinionDBActions.getUsersOpinionOnContent(contentPointer, userID);
    }
  },

  '/account/addOpinion': {
    /**
     * Adds an opinion, will overwrite the previous opinion if one existed.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const { contentPointer, rating } = req.body;

      return opinionDBActions.addOpinion(contentPointer, rating, userID);
    }
  },

  '/account/removeOpinion': {
    /**
     * Removes an opinion, returns `true` if the opinion existed and was deleted, returns false if it didn't exist to
     * begin with.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const { contentPointer, rating } = req.body;

      return opinionDBActions.removeOpinion(contentPointer, rating, userID);
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
      const userEmail = req.user.email;
      const snipbit = req.body;

      return snipbitDBActions.addNewSnipbit(userID, userEmail, snipbit);
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
      const userEmail = req.user.email;
      const bigbit = req.body;

      return bigbitDBActions.addNewBigbit(userID, userEmail, bigbit);
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
      const userEmail = req.user.email;

      return storyDBActions.createNewStory(userID, userEmail, newStory);
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
      const generalSearchConfig = getGeneralContentSearchConfiguration(queryParams);
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return contentDBActions.getContent(generalSearchConfig, searchFilter, resultManipulation)
      .then(R.map(removeMetadataForResponse));
    }
  },

  '/opinions/:contentType/:contentID': {
    /**
    * Get's `Rating`s for some specific `Content`.
    */
    get: (req, res): Promise<Ratings> => {
      const params = req.params;
      const contentPointer: ContentPointer = {
        contentType: parseInt(params.contentType),
        contentID: params.contentID
      };

      return opinionDBActions.getAllOpinionsOnContent(contentPointer);
    }
  },

  '/qa/:tidbitType/:tidbitID': {
    /**
     * Get's the full QA document for a specific tidbit.
     */
    get: (req, res): Promise<QA<any>> => {
      const { tidbitType, tidbitID } = req.params;

      return qaDBActions.getQAForTidbit(true, { tidbitType: parseInt(tidbitType), targetID: tidbitID });
    }
  },

  '/qa/:tidbitType/:tidbitID/askQuestion': {
    /**
     * Asks a question (requires the user be logged-in).
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { questionText, codePointer } = req.body;
      const { _id, email } = req.user;

      return qaDBActions.askQuestion(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionText,
        codePointer,
        _id,
        email
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/editQuestion': {
    /**
     * Edits a question that the currently logged-in user asked.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { questionID, questionText, codePointer } = req.body;
      const { _id } = req.user;

      return qaDBActions.editQuestion(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        questionText,
        codePointer,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/rateQuestion': {
    /**
     * Rates a question.
     *
     * Returns true if the intended rating was added. If the document was left unchanged returns false.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { vote, questionID } = req.body;
      const { _id } = req.user;

      return qaDBActions.rateQuestion(
        true,
        vote,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/removeQuestionRating': {
    /**
     * Removes the rating for a question.
     *
     * Returns true if a rating was removed, otherwise returns false (if no ratings existed at all for instance).
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { questionID } = req.body;
      const { _id } = req.user;

      return qaDBActions.removeQuestionRating(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/pinQuestion': {
    /**
     * Pins/unpins a question, only the author of the tidbit is allowed to do this.
     *
     * Returns true if the pin/un-pin was performed and the original document was modified.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { pin, questionID } = req.body;
      const { _id } = req.user;

      return qaDBActions.pinQuestion(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        pin,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/answerQuestion': {
    /**
     * Answers an existing question, returns true if all succeeded and the answer was added.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { answerText, questionID } = req.body;
      const { _id, email } = req.user;

      return qaDBActions.answerQuestion(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        answerText,
        _id,
        email
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/editAnswer': {
    /**
     * Edits an existing answer that the user wrote, returns true if edit successful.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { answerText, answerID } = req.body;
      const { _id } = req.user;

      return qaDBActions.editAnswer(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        answerID,
        answerText,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/rateAnswer': {
    /**
     * Rates an answer.
     *
     * Returns true if the intended rating was added. If the document was left unchanged returns false.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { vote, answerID } = req.body;
      const { _id } = req.user;

      return qaDBActions.rateAnswer(
        true,
        vote,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        answerID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/removeAnswerRating': {
    /**
     * Removes a rating on an answer.
     *
     * Returns true if a rating existed before and it was removed successfully.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { answerID } = req.body;
      const { _id } = req.user;

      return qaDBActions.removeAnswerRating(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        answerID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/pinAnswer': {
    /**
     * Pins an answer, only the author of the tidbit is allowed to perform this action.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { pin, answerID } = req.body;
      const { _id } = req.user;

      return qaDBActions.pinAnswer(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        answerID,
        pin,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/comment/question': {
    /**
     * Comment on a question.
     *
     * Returns true if the comment is added successfully.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { questionID, commentText } = req.body;
      const { _id, email } = req.user;

      return qaDBActions.commentOnQuestion(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        commentText,
        _id,
        email
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/editComment/question': {
    /**
     * Edits a comment created by the logged-in user.
     *
     * Returns true if the comment was edited.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { commentText, commentID } = req.body;
      const { _id } = req.user;

      return qaDBActions.editQuestionComment(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        commentID,
        commentText,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/comment/answer': {
    /**
     * Comment on an answer.
     *
     * Returns true if the comment is added successfully.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { answerID, commentText } = req.body;
      const { _id, email } = req.user;

      return qaDBActions.commentOnAnswer(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        answerID,
        commentText,
        _id,
        email
      );
    }
  }
}

/**
 * Get's `sortByLastModified` from query params as a boolean. Will default to `false` unless "true" is passed.
 */
const getSortByLastModifiedAsBoolean = ({ sortByLastModified }): boolean => sortByLastModified === "true";

/**
 * Get's `sortByTextScore` from query params as a boolean. Will default to `false` unless "true" is passed.
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
 * Get's the `includeSnipbits` as a string. Will default to `true` unless "false" is passed.
 */
const getIncludeSnipbits = ({ includeSnipbits }): boolean => includeSnipbits !== "false";

/**
 * Get's the `includeBigbits` as a string. Will default to `true` unless "false" is passed.
 */
const getIncludeBigbits = ({ includeBigbits }): boolean => includeBigbits !== "false";

/**
 * Get's the `includeStories` as a bool. Will default to `true` unless "false" is passed.
 */
const getIncludeStories = ({ includeStories }): boolean => includeStories !== "false";

/**
 * Get's the `includeEmptyStories` as a bool. Will default to `false` unless "true" is passed.
 */
const getIncludeEmptyStories = ({ includeEmptyStories }): boolean => includeEmptyStories === "true";

/**
 * Get's the `restrictLanguage` as a string array.
 */
const getRestrictLanguage = ({ restrictLanguage }): string[] => {
  return maybeMap(R.split(","))(restrictLanguage);
}

/**
 * For extracting the general search configuration [for `Content`] from the query parameters.
 */
const getGeneralContentSearchConfiguration = (queryParams): GeneralSearchConfiguration => {
  return {
    includeSnipbits: getIncludeSnipbits(queryParams),
    includeBigbits: getIncludeBigbits(queryParams),
    includeStories: getIncludeStories(queryParams)
  }
}

/**
 * For staying DRY while extracting `ContentResultManipulation` from query parameters.
 */
const getContentResultManipulationFromQP = ( queryParams ): ContentResultManipulation => {
  return {
    sortByLastModified: getSortByLastModifiedAsBoolean(queryParams),
    sortByTextScore: getSortByTextScoreAsBoolean(queryParams),
    pageNumber: getPageNumberAsInt(queryParams),
    pageSize: getPageSizeAsInt(queryParams)
  }
}

/**
 * For staying DRY while extracting `ContentSearchFilter | StorySearchFilter` from query parameters.
 */
const getContentSearchFilterFromQP = ( queryParams ): ContentSearchFilter | StorySearchFilter  => {
  return {
    author: getAuthorAsString(queryParams),
    searchQuery: getSearchQueryAsString(queryParams),
    includeEmptyStories: getIncludeEmptyStories(queryParams),
    restrictLanguage: getRestrictLanguage(queryParams)
  }
}

/**
 * Metadata the backend uses such as `textScore` need to be stripped prior to sending to the frontend.
 */
const removeMetadataForResponse = (obj) => {
  delete obj.textScore;
  return obj;
}
