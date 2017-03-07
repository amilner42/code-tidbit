/// Module for encapsulating helper functions for the story model.

import * as R from "ramda";
import * as kleen from "kleen";
import { ObjectID, Collection } from 'mongodb';
import moment from "moment";

import { renameIDField, collection, ID } from '../db';
import { malformedFieldError, isNullOrUndefined } from '../util';
import { mongoIDSchema, nameSchema, descriptionSchema, optional, tagsSchema, nonEmptyArraySchema } from "./kleen-schemas";
import { MongoID, ErrorCode } from '../types';
import { Snipbit, snipbitDBActions } from './snipbit.model';
import { Bigbit, bigbitDBActions } from './bigbit.model';
import { Tidbit, TidbitPointer, TidbitType, tidbitPointerSchema, tidbitDBActions } from './tidbit.model';


/**
 * Internal for staying DRY.
 */
interface StoryBase {
  _id?: MongoID;
  id?: MongoID;
  author: MongoID;
  name: string;
  description: string;
  tags: string[];
  createdAt?: Date;
  lastModified?: Date;
}

/**
 * The internal search filter representation.
 */
interface InternalStorySearchFilter {
  author?: ObjectID;
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
 * The filters allowed when searching stories.
 */
export interface StorySearchFilter {
  author?: MongoID;
}

/**
* The schema for validating a story.
*/
const storySchema: kleen.typeSchema = {
  objectProperties: {
    "id": optional(mongoIDSchema(malformedFieldError("story.id"))),
    "author": mongoIDSchema(malformedFieldError("author")),
    "name": nameSchema(ErrorCode.storyNameEmpty, ErrorCode.storyNameTooLong),
    "description": descriptionSchema(ErrorCode.storyDescriptionEmpty),
    "tags": tagsSchema(ErrorCode.storyEmptyTag, ErrorCode.storyNoTags),
    "tidbitPointers": {
      arrayElementType: tidbitPointerSchema,
      typeFailureError: malformedFieldError("tidbitPointers")
    },
  }
};

/**
 * The schema for validating the user-input for a new story or for editing the
 * information on an existing story.
 */
const newStorySchema: kleen.typeSchema = {
  objectProperties: {
    "name": nameSchema(ErrorCode.storyNameEmpty, ErrorCode.storyNameTooLong),
    "description": descriptionSchema(ErrorCode.storyDescriptionEmpty),
    "tags": tagsSchema(ErrorCode.storyEmptyTag, ErrorCode.storyNoTags)
  },
  typeFailureError: malformedFieldError("Story information")
};

/**
 * Prepares a story for the response.
 *
 * - Rename `_id` to `id`.
 */
const prepareStoryForResponse = (story: Story): Story => {
  renameIDField(story);
  return story;
};

/**
 * Prepares an expanded story for the response.
 *
 * - Rename `_id` to `id`.
 */
const prepareExpandedStoryForResponse = (expandedStory: ExpandedStory): ExpandedStory => {
  renameIDField(expandedStory);
  return expandedStory;
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
      const expandedStory: ExpandedStory = {
        _id: story._id,
        id: story.id,
        name: story.name,
        author: story.author,
        description: story.description,
        tags: story.tags,
        tidbits: tidbits,
        lastModified: story.lastModified,
        createdAt: story.createdAt
      };

      return prepareExpandedStoryForResponse(expandedStory);
    });
  },

  /**
   * Gets stories from the db.
   */
  getStories: (filter: StorySearchFilter) => {
    return collection("stories")
    .then((StoryCollection) => {
      const mongoSearchFilter: InternalStorySearchFilter = {};

      if(!isNullOrUndefined(filter.author)) {
        mongoSearchFilter.author = ID(filter.author);
      }

      return StoryCollection.find(mongoSearchFilter).toArray();
    })
    .then((stories) => {
      return stories.map(prepareStoryForResponse);
    });
  },

  /**
   * Gets a single story from the database. If `expandStory` then the
   * `tidbitPointers` are expanded.
   */
  getStory: (storyID: MongoID, expandStory: Boolean): Promise<Story | ExpandedStory> => {
    return collection('stories')
    .then((storyCollection) => {
      return storyCollection.findOne({ _id: ID(storyID) }) as Promise<Story>;
    })
    .then((story) => {
      if(!story) {
        return Promise.reject({
          message: `No story exists with id: ${storyID}`,
          errorCode: ErrorCode.storyDoesNotExist
        });
      }

      if(expandStory) {
        return Promise.resolve(storyDBActions.expandStory(story));
      }

      return Promise.resolve(prepareStoryForResponse(story));
    });
  },

  /**
   * Creates a new story for the user.
   */
  createNewStory: (userID, newStory: NewStory): Promise<{ targetID: MongoID }> => {
    return kleen.validModel(newStorySchema)(newStory)
    .then(() => {
      return collection("stories");
    })
    .then((StoryCollection) => {
      const dateNow = moment.utc().toDate();

      // Convert to a full `Story` by adding missing fields with defaults.
      const story: Story = {
        name: newStory.name,
        description: newStory.description,
        tags: newStory.tags,
        // DB-added fields here:
        //  - Author
        //  - Add an empty array of tidbit pointers.
        author: userID,
        tidbitPointers: [],
        createdAt: dateNow,
        lastModified: dateNow
      };

      return StoryCollection.insertOne(story);
    })
    .then((story) => {
      return { targetID: story.insertedId.toHexString() };
    });
  },

  /**
   * Updates the information connected to a story. This will only allow the
   * author to edit the information.
   */
  updateStoryInfo: (userID, storyID, editedInfo): Promise<{ targetID: MongoID }> => {
    return kleen.validModel(newStorySchema)(editedInfo)
    .then(() => {
      return collection('stories')
    })
    .then((storyCollection) => {
      const dateNow = moment.utc().toDate();

      return storyCollection.findOneAndUpdate(
        { _id: ID(storyID),
          author: userID
        },
        { $set: Object.assign(editedInfo, { lastModified: dateNow }) },
        {}
      );
    })
    .then((updateStoryResult) => {
      if(updateStoryResult.value) {
        return { targetID: updateStoryResult.value._id };
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
   */
  addTidbitPointersToStory: (userID, storyID, newTidbitPointers: TidbitPointer[]): Promise<ExpandedStory> => {

    const nonEmptyTidbitPointersSchema = nonEmptyArraySchema(
      tidbitPointerSchema,
      {
        errorCode: ErrorCode.internalError,
        message: "You can't add 0 tidbits to a story..."
      },
      malformedFieldError("New stories")
    );

    return kleen.validModel(nonEmptyTidbitPointersSchema)(newTidbitPointers)
    .then(() => {
      return storyDBActions.getStory(storyID, false);
    })
    .then<boolean[]>((story) => {
      if(!ID(story.author).equals(ID(userID))) {
        return Promise.reject({
          message: "You can only edit your own stories",
          errorCode: ErrorCode.storyEditorMustBeAuthor
        });
      }

      return Promise.all(newTidbitPointers.map(tidbitDBActions.tidbitPointerExists));
    })
    .then<Collection>((tidbitExistsArray) => {
      if (!R.all(R.identity, tidbitExistsArray)) {
        return Promise.reject({
          errorCode: ErrorCode.storyAddingNonExistantTidbit,
          message: "A tidbitPointer you were adding does not point to an existant tidbit."
        });
      }

      return collection("stories");
    })
    .then((storyCollection) => {
      const dateNow = moment.utc().toDate();

      return storyCollection.findOneAndUpdate(
        { _id: ID(storyID), author: userID },
        { $push: { tidbitPointers: { $each: newTidbitPointers } }
        , $set: { lastModified: dateNow }
        },
        { returnOriginal: false }
      );
    })
    .then<ExpandedStory>((updatedStoryResult) => {
      if(updatedStoryResult.value) {
        return storyDBActions.expandStory(updatedStoryResult.value);
      }

      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "There was an internal error when updating your story"
      });
    });
  }
};
