/// Module for encapsulating helper functions for the story model.

import * as kleen from "kleen";

import { ObjectID } from 'mongodb';
import { renameIDField, collection, ID } from '../db';
import { malformedFieldError, isNullOrUndefined } from '../util';
import { mongoIDSchema, nameSchema, descriptionSchema, optional, tagsSchema } from "./kleen-schemas";
import { MongoID, ErrorCode } from '../types';

/**
* A story will represent a series of tidbits that the user can go through. Of
* course, in the future we may have additional things like
* quizzes/markdown-frames.
*/
export interface Story {
  _id?: MongoID;
  id?: MongoID;
  author: MongoID;
  name: string;
  description: string;
  tags: string[];
  pages: StoryPage[];
}

export interface NewStory {
  name: string;
  description: string;
  tags: string[];
}

/**
* A StoryPage refers to a single part of the story, this could be one
* `snipbit`, `bigbit`, or other things as more develop.
*/
export interface StoryPage {
  storyType: StoryPageType;
  targetID: string;
}

/**
* The current possibly
*/
export enum StoryPageType {
  Snipbit = 1,
  Bigbit
}

/**
 * The filters allowed when searching stories.
 */
export interface StorySearchFilter {
  author?: MongoID;
}

/**
 * The internal search filter representation.
 */
interface InternalStorySearchFilter {
  author?: ObjectID;
}

/**
* The schema for validating a StoryPage.
*/
const storyPageSchema: kleen.typeSchema = {
  objectProperties: {
    "storyType": {
      primitiveType: kleen.kindOfPrimitive.number,
      restriction: (storyType: number) => {
        if(!(storyType in StoryPageType)) {
          return Promise.reject({
            errorCode: ErrorCode.storyInvalidPageType,
            message: "Invalid story type."
          });
        }
      },
      typeFailureError: malformedFieldError("storyPage.storyType")
    },
    "targetID": mongoIDSchema(malformedFieldError("storyPage.targetID")),
  }
};

/**
* The schema for validating a full story.
*/
const storySchema: kleen.typeSchema = {
  objectProperties: {
    "id": optional(mongoIDSchema(malformedFieldError("story.id"))),
    "author": mongoIDSchema(malformedFieldError("author")),
    "name": nameSchema(ErrorCode.storyNameEmpty, ErrorCode.storyNameTooLong),
    "description": descriptionSchema(ErrorCode.storyDescriptionEmpty),
    "tags": tagsSchema(ErrorCode.storyEmptyTag, ErrorCode.storyNoTags),
    "pages": {
      arrayElementType: storyPageSchema,
      typeFailureError: malformedFieldError("pages")
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
export const prepareStoryForResponse = (story: Story) => {
  renameIDField(story);
  return story;
}

/**
 * All the db helpers for a story.
 */
export const storyDBActions = {

  /**
   * Gets stories from the db,
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
   * Gets a single story from the database.
   */
  getStory: (storyID: MongoID): Promise<Story> => {
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

      // Convert to a full `Story` by adding missing fields with defaults.
      const story: Story = {
        name: newStory.name,
        description: newStory.description,
        tags: newStory.tags,
        // DB-added fields here:
        //  - Author
        //  - Add blank pages.
        author: userID,
        pages: []
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
        return { targetID: updateStoryResult.value._id };
      }

      return Promise.reject({
        errorCode: ErrorCode.internalError,
        message: "You do not have a story with that ID."
      });
    });
  }
};
