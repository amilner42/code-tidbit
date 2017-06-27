/// Module for encapsulating helper functions for the story model.

import * as R from "ramda";
import * as kleen from "kleen";
import { Collection } from 'mongodb';
import moment from "moment";

import { opinionDBActions } from "./opinion.model";
import { renameIDField, collection, toMongoObjectID, sameID, updateOneResultHandlers, findOneAndUpdateResultHandlers } from '../db';
import { malformedFieldError, isNullOrUndefined, dropNullAndUndefinedProperties } from '../util';
import { nameSchema, descriptionSchema, optional, tagsSchema, nonEmptyArraySchema } from "./kleen-schemas";
import { MongoID, MongoObjectID, ErrorCode, TargetID } from '../types';
import { completedDBActions } from './completed.model';
import { ContentSearchFilter, ContentResultManipulation, ContentType, ContentPointer, getContent, getLanguages } from "./content.model";
import { Snipbit, snipbitDBActions } from './snipbit.model';
import { Bigbit, bigbitDBActions } from './bigbit.model';
import { Tidbit, TidbitPointer, TidbitType, tidbitPointerSchema, tidbitDBActions } from './tidbit.model';


/**
 * Internal for staying DRY.
 */
interface StoryBase {
  name: string;
  description: string;
  tags: string[];

  _id?: MongoID;
  id?: MongoID;
  author?: MongoID;
  authorEmail?: string;
  createdAt?: Date;
  lastModified?: Date;
  userHasCompleted?: boolean[];
  languages?: string[];
  likes?: number;       // In the `opinions` collection, attached by the backend.
}

/**
* A story will represent a series of tidbits that the user can go through. In
* this form, all the tidbits are simply `TidbitPointer`s (to keep the story
* compact), if you need all those tidbits then you need an `ExpandedStory`.
*/
export type Story = StoryBase & { tidbitPointers: TidbitPointer[]; };

/**
 * An expanded story is similar to a `Story` but we expand the tidbit pointers.
 */
export type ExpandedStory = StoryBase &  { tidbits: Tidbit[]; };

/**
 * A `NewStory` represents the information part of a story which is all we
 * require for new stories, but it can also used for updating the information
 * of an existing story.
 */
export interface NewStory {
  name: string;
  description: string;
  tags: string[];
}

/**
 * The search options.
 */
export interface StorySearchFilter extends ContentSearchFilter {
  includeEmptyStories?: boolean;
}

/**
 * The result manipulation options.
 */
export interface StoryResultManipulation extends ContentResultManipulation { }

/**
 * The schema for validating the user-input for a new story or for editing the
 * information on an existing story.
 */
const newStorySchema: kleen.objectSchema = {
  objectProperties: {
    "name": nameSchema(ErrorCode.storyNameEmpty, ErrorCode.storyNameTooLong),
    "description": descriptionSchema(ErrorCode.storyDescriptionEmpty, ErrorCode.storyDescriptionTooLong),
    "tags": tagsSchema(ErrorCode.storyEmptyTag, ErrorCode.storyNoTags)
  },
  typeFailureError: malformedFieldError("Story information")
};

/**
 * Prepares a story/expanded-story for the response.
 *  -  Fetches and attaches ratings.
 *  - Rename `_id` to `id`.
 */
const prepareStoryForResponse = (story: Story | ExpandedStory): Promise<Story | ExpandedStory> => {
  const storyCopy = R.clone(story);
  const contentPointer: ContentPointer = {
    contentID: storyCopy._id,
    contentType: ContentType.Story
  };

  return opinionDBActions.getOpinionsCountOnContent(contentPointer, false)
  .then(({ likes }) => {
    storyCopy.likes = likes;

    return renameIDField(storyCopy);
  });
};

/**
 * All the db helpers for a story.
 */
export const storyDBActions = {

  /**
   * Expands a story, this means switching all the `tidbitPointers` with
   * `tidbits`. Also prepares the expanded story for the response.
   */
  expandStory: (story: Story): Promise<ExpandedStory> => {

    return Promise.all(story.tidbitPointers.map(tidbitDBActions.expandTidbitPointer))
    .then((tidbits) => {
      const storyBase: StoryBase = R.omit(["tidbitPointers"])(story);
      const expandedStory: ExpandedStory = R.merge({ tidbits },  storyBase);

      return prepareStoryForResponse(expandedStory);
    });
  },

  /**
   * Gets stories from the db, customizable through `StorySearchFilter` and `StoryResultManipulation`.
   */
  getStories: (filter: StorySearchFilter, resultManipulation: StoryResultManipulation): Promise<[boolean, Story[]]> => {
    return getContent(ContentType.Story, filter, resultManipulation, prepareStoryForResponse);
  },

  /**
   * Gets a single story from the database. If `expandStory` then the
   * `tidbitPointers` are expanded.
   */
  getStory: (storyID: MongoID, expandStory: boolean, withCompletedForUser: MongoID): Promise<Story | ExpandedStory> => {
    return collection('stories')
    .then<Story>((storyCollection) => {
      return storyCollection.findOne({ _id: toMongoObjectID(storyID) });
    })
    .then((story) => {
      if(!story) {
        return Promise.reject({
          message: `No story exists with id: ${storyID}`,
          errorCode: ErrorCode.storyDoesNotExist
        });
      }

      if(!withCompletedForUser) {
        return Promise.resolve(story);
      }

      return Promise.all<boolean>(
        story.tidbitPointers.map((tidbitPointer) => {
          return completedDBActions.isCompleted(
            {
              tidbitPointer: tidbitPointer,
              user: withCompletedForUser
            },
            withCompletedForUser,
            false
          );
        })
      )
      .then((completedArray) => {
        story.userHasCompleted = completedArray;
        return story;
      });
    })
    .then<Story | ExpandedStory>((story) => {
      if(expandStory) {
        return storyDBActions.expandStory(story);
      }

      return prepareStoryForResponse(story);
    });

  },

  /**
   * Creates a new story for the user.
   *
   * Returns the ID of the newly created story.
   */
  createNewStory: (userID: MongoID, userEmail: string, newStory: NewStory, doValidation = true): Promise<TargetID> => {
    return (doValidation ? kleen.validModel(newStorySchema)(newStory) : Promise.resolve())
    .then(() => {
      return collection("stories");
    })
    .then((StoryCollection) => {
      const dateNow = moment.utc().toDate();
      const defaultFields = {
        author: userID,
        authorEmail: userEmail,
        tidbitPointers: [],
        createdAt: dateNow,
        lastModified: dateNow,
        languages: []
      };
      // Convert to a full `Story` by adding missing fields with defaults.
      const story: Story = R.merge(newStory, defaultFields);

      return StoryCollection.insertOne(story);
    })
    .then((insertStoryResult) => {
      return { targetID: insertStoryResult.insertedId };
    });
  },

  /**
   * Updates the information connected to a story, only the author is allowed to edit the information.
   *
   * Returns the ID of the edited story (same as `storyID`).
   */
  updateStoryInfo: (userID: MongoID, storyID: MongoID, editedInfo: NewStory, doValidation = true): Promise<TargetID> => {
    return (doValidation ? kleen.validModel(newStorySchema)(editedInfo) : Promise.resolve())
    .then(() => {
      return collection('stories')
    })
    .then((storyCollection) => {
      const dateNow = moment.utc().toDate();

      return storyCollection.updateOne(
        { _id: toMongoObjectID(storyID),
          author: toMongoObjectID(userID)
        },
        { $set: R.merge(editedInfo, { lastModified: dateNow }) },
        {}
      );
    })
    .then(updateOneResultHandlers.rejectIfResultNotOK)
    .then((updateStoryResult) => {
      if(updateStoryResult.modifiedCount === 1) {
        return Promise.resolve({ targetID: storyID });
      }

      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "You do not have a story with that ID."
      });
    });
  },

  /**
   * Adds `TidbitPointer`s to an existing story. Verifies that:
   *  - Story already exists
   *  - Author of story is current user
   *  - `newTidbitPointers` point to actual tidbits.
   *
   * Returns the updated story in expanded form.
   */
  addTidbitPointersToStory:
    ( userID: MongoID
    , storyID: MongoID
    , newTidbitPointers: TidbitPointer[]
    , doValidation = true
    ): Promise<ExpandedStory> => {

    const nonEmptyTidbitPointersSchema = nonEmptyArraySchema(
      tidbitPointerSchema,
      {
        errorCode: ErrorCode.internalError,
        message: "You can't add 0 tidbits to a story..."
      },
      malformedFieldError("New stories")
    );

    return (doValidation ? kleen.validModel(nonEmptyTidbitPointersSchema)(newTidbitPointers) : Promise.resolve())
    .then(() => {
      return storyDBActions.getStory(storyID, false, null);
    })
    .then<Tidbit[]>((story) => {
      if(!sameID(userID, story.author)) {
        return Promise.reject({
          message: "You can only edit your own stories",
          errorCode: ErrorCode.storyEditorMustBeAuthor
        });
      }

      return Promise.all(newTidbitPointers.map(tidbitDBActions.expandTidbitPointer));
    })
    .then<[Collection, string[]]>((tidbits) => {

      // If it contains an `id` then it's a record from the DB and not an error object.
      const foundInDB = ( record ): boolean => !isNullOrUndefined(record.id);

      // Adds the unique languages from a tidbit to the accumulator, used in `reduce` below.
      const addLanguages = (languageAcc: Set<string>, tidbit: Tidbit): Set<string> => {
        getLanguages(tidbit).map(lang => languageAcc.add(lang));
        return languageAcc;
      }

      const tidbitLanguages = Array.from(R.reduce(addLanguages, new Set<string>([]), tidbits));

      if (!R.all(foundInDB, tidbits)) {
        return Promise.reject({
          errorCode: ErrorCode.storyAddingNonExistantTidbit,
          message: "A tidbitPointer you were adding does not point to an existant tidbit."
        });
      }

      return Promise.all([collection("stories"), tidbitLanguages]);
    })
    .then(([storyCollection, tidbitLanguages]) => {
      const dateNow = moment.utc().toDate();

      return storyCollection.findOneAndUpdate(
        { _id: toMongoObjectID(storyID), author: toMongoObjectID(userID) },
        { $push: { tidbitPointers: { $each: newTidbitPointers } }
        , $set: { lastModified: dateNow }
        , $addToSet: { languages: { $each: tidbitLanguages } }
        },
        { returnOriginal: false }
      );
    })
    .then(findOneAndUpdateResultHandlers.rejectIfResultNotOK)
    .then(findOneAndUpdateResultHandlers.rejectIfValueNotPresent)
    .then<ExpandedStory>((updatedStoryResult) => {
      return storyDBActions.expandStory(updatedStoryResult.value);
    });
  }
};
