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
     * @refer `userDBActions.getUserID`.
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
     * @refer `userDBActions.updateUser`.
     */
    post: (req, res): Promise<User> => {
      const userUpdateObject = req.body;
      const userID = req.user._id;

      return userDBActions.updateUser(userID, userUpdateObject);
    }
  },

  '/account/addCompleted': {
    /**
     * @refer `completedDBActions.addCompleted`.
     */
    post: (req, res): Promise<TargetID> => {
      const userID = req.user._id;
      const completed = req.body;

      return completedDBActions.addCompleted(completed, userID);
    }
  },

  '/account/removeCompleted': {
    /**
     * @refer `completedDBActions.removeCompleted`.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const completed = req.body;

      return completedDBActions.removeCompleted(completed, userID);
    }
  },

  '/account/checkCompleted': {
    /**
     * @refer `completedDBActions.isCompleted`.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const completed = req.body;

      return completedDBActions.isCompleted(completed, userID);
    }
  },

  '/account/getOpinion/:contentType/:contentID': {
    /**
     * @refer `opinionDBActions.getUsersOpinionOnContent`.
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
     * @refer `opinionDBActions.addOpinion`.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const { contentPointer, rating } = req.body;

      return opinionDBActions.addOpinion(contentPointer, rating, userID);
    }
  },

  '/account/removeOpinion': {
    /**
     * @refer `opinionDBActions.removeOpinion`.
     */
    post: (req, res): Promise<boolean> => {
      const userID = req.user._id;
      const { contentPointer, rating } = req.body;

      return opinionDBActions.removeOpinion(contentPointer, rating, userID);
    }
  },

  '/snipbits': {
    /**
     * @refer `snipbitDBActions.getSnipbits`.
     */
    get: (req, res): Promise<Snipbit[]> => {
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return snipbitDBActions.getSnipbits(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    },

    /**
     * @refer `snipbitDBActions.addNewSnipbit`.
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
     * @refer `bigbitDBActions.getBigbits`.
     */
    get: (req, res): Promise<Bigbit[]> => {
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return bigbitDBActions.getBigbits(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    },

    /**
     * @refer `bigbitDBActions.addNewBigbit`.
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
     * @refer `snipbitDBActions.getSnipbit`.
     */
    get: (req, res): Promise<Snipbit> => {
      const params = req.params;
      const snipbitID = params["id"];

      return snipbitDBActions.getSnipbit(snipbitID);
    }
  },

  '/bigbits/:id': {
    /**
     * @refer `bigbitDBActions.getBigbit`.
     */
    get: (req, res): Promise<Bigbit> => {
      const params = req.params;
      const bigbitID = params["id"];

      return bigbitDBActions.getBigbit(bigbitID);
    }
  },

  '/stories': {
    /**
     * @refer `storyDBActions.getStories`.
     */
    get: (req, res): Promise<Story[]> => {
      const userID = req.user._id;
      const queryParams = req.query;
      const searchFilter = getContentSearchFilterFromQP(queryParams);
      const resultManipulation = getContentResultManipulationFromQP(queryParams);

      return storyDBActions.getStories(searchFilter, resultManipulation).then(R.map(removeMetadataForResponse));
    },

    /**
     * @refer `storyDBActions.createNewStory`.
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
     * @refer `storyDBActions.getStory`.
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
     * @refer `storyDBActions.updateStoryInfo`.
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
     * @refer `storyDBActions.addTidbitPointersToStory`.
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
     * @refer `tidbitDBActions.getTidbits`.
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
     * @refer `contentDBActions.getContent`.
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
    * @refer `opinionDBActions.getAllOpinionsOnContent`.
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
     * @refer `qaDBActions.getQAForTidbit`.
     */
    get: (req, res): Promise<QA<any>> => {
      const { tidbitType, tidbitID } = req.params;

      return qaDBActions.getQAForTidbit(true, { tidbitType: parseInt(tidbitType), targetID: tidbitID });
    }
  },

  '/qa/:tidbitType/:tidbitID/askQuestion': {
    /**
     * @refer `qaDBActions.askQuestion`.
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
     * @refer `qaDBActions.editQuestion`.
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

  '/qa/:tidbitType/:tidbitID/deleteQuestion': {
    /**
     * @refer `qaDBActions.deleteQuestion`.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { questionID } = req.body;
      const { _id } = req.user;

      return qaDBActions.deleteQuestion(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/rateQuestion': {
    /**
     * @refer `qaDBActions.rateQuestion`.
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
     * @refer `qaDBActions.removeQuestionRating`.
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
     * @refer `qaDBActions.pinQuestion`.
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
     * @refer `qaDBActions.answerQuestion`.
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
     * @refer `qaDBActions.editAnswer`.
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

  '/qa/:tidbitType/:tidbitID/deleteAnswer': {
    /**
     * @refer `qaDBActions.deleteAnswer`.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { answerID } = req.body;
      const { _id } = req.user;

      return qaDBActions.deleteAnswer(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        answerID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/rateAnswer': {
    /**
     * @refer `qaDBActions.rateAnswer`.
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
     * @refer `qaDBActions.removeAnswerRating`.
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
     * @refer `qaDBActions.pinAnswer`.
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
     * @refer `qaDBActions.commentOnQuestion`.
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
     * @refer `qaDBActions.editQuestionComment`.
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

  '/qa/:tidbitType/:tidbitID/deleteComment/question': {
    /**
     * @refer `qaDBActions.deleteQuestionComment`.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { commentID } = req.body;
      const { _id } = req.user;

      return qaDBActions.deleteQuestionComment(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        commentID,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/comment/answer': {
    /**
     * @refer `qaDBActions.commentOnAnswer`.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { answerID, questionID, commentText } = req.body;
      const { _id, email } = req.user;

      return qaDBActions.commentOnAnswer(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        questionID,
        answerID,
        commentText,
        _id,
        email
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/editComment/answer': {
    /**
     * @refer `qaDBActions.editAnswerComment`.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { commentID, commentText } = req.body;
      const { _id } = req.user;

      return qaDBActions.editAnswerComment(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        commentID,
        commentText,
        _id
      );
    }
  },

  '/qa/:tidbitType/:tidbitID/deleteComment/answer': {
    /**
     * @refer `qaDBActions.deleteAnswerComment`.
     */
    post: (req, res): Promise<boolean> => {
      const { tidbitType, tidbitID } = req.params;
      const { commentID } = req.body;
      const { _id } = req.user;

      return qaDBActions.deleteAnswerComment(
        true,
        { tidbitType: parseInt(tidbitType), targetID: tidbitID },
        commentID,
        _id
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
