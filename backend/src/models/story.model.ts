/// Module for encapsulating helper functions for the story model.

import * as R from "ramda";
import * as kleen from "kleen";
import { ObjectID, Collection } from 'mongodb';

import { renameIDField, collection, ID } from '../db';
import { malformedFieldError, isNullOrUndefined } from '../util';
import { mongoIDSchema, nameSchema, descriptionSchema, optional, tagsSchema, nonEmptyArraySchema } from "./kleen-schemas";
import { MongoID, ErrorCode } from '../types';
import { Snipbit, snipbitDBActions } from './snipbit.model';
import { Bigbit, bigbitDBActions } from './bigbit.model';


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
}

/**
 * The internal search filter representation.
 */
interface InternalStorySearchFilter {
  author?: ObjectID;
}

/**
* A story will represent a series of tidbits that the user can go through. Of
* course, in the future we may have additional things like quizzes.
*/
export type Story = StoryBase & { pages: StoryPage[]; };

/**
 * An expanded story is similar to a `Story` but we expand the pages instead
 * of just having them be pointers.
 */
export type ExpandedStory = StoryBase &  { expandedPages: ExpandedStoryPage[]; };

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
* A StoryPage refers to a single part of the story, this could be one
* `snipbit`, `bigbit`, or other things as more develop.
*/
export interface StoryPage {
  storyType: StoryPageType;
  targetID: string;
}

/**
* The current possible pages.
*/
export enum StoryPageType {
  Snipbit = 1,
  Bigbit
}

/**
 * The types of the expanded pages, should be the actual values which
 * `StoryPageType` is referring to.
 */
export type ExpandedStoryPage = Snipbit | Bigbit;

/**
 * The filters allowed when searching stories.
 */
export interface StorySearchFilter {
  author?: MongoID;
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
* The schema for validating a story.
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
   * Returns [a promise to] true if the page exists.
   */
  pageExists: (page: StoryPage): Promise<boolean> => {
    switch(page.storyType) {
      case StoryPageType.Snipbit:
        return snipbitDBActions.hasSnipbit(page.targetID);

      case StoryPageType.Bigbit:
        return bigbitDBActions.hasBigbit(page.targetID);
    }
  },

  /**
   * Gets the expanded page from appropriate collection.
   */
  expandPage: (page: StoryPage): Promise<ExpandedStoryPage> => {
    switch(page.storyType) {
      case StoryPageType.Snipbit:
        return snipbitDBActions.getSnipbit(page.targetID);

      case StoryPageType.Bigbit:
        return bigbitDBActions.getBigbit(page.targetID);
    }
  },

  /**
   * Expands a story, this means switching all the `pages` with `expandedPages`.
   * Also prepares the expanded story for the response.
   */
  expandStory: (story: Story): Promise<ExpandedStory> => {

    return Promise.all(story.pages.map(storyDBActions.expandPage))
    .then((expandedPages) => {
      const expandedStory: ExpandedStory = {
        _id: story._id,
        id: story.id,
        name: story.name,
        author: story.author,
        description: story.description,
        tags: story.tags,
        expandedPages: expandedPages
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
   * Gets a single story from the database. If `expandStory` then the `pages`
   * are expanded.
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
        return storyDBActions.expandStory(story);
      }

      return prepareStoryForResponse(story);
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
  },

  /**
   * Adds tidbits to an existing story. Verifies that:
   *  - Story already exists
   *  - Author of story is current user
   *  - `newStoryPages` point to actual tidbits.
   */
  addTidbitsToStory: (userID, storyID, newStoryPages: StoryPage[]): Promise<ExpandedStory> => {

    const nonEmptyStoryPagesSchema = nonEmptyArraySchema(
      storyPageSchema,
      {
        errorCode: ErrorCode.internalError,
        message: "You can't add 0 tidbits to a story..."
      },
      malformedFieldError("New stories")
    );

    return kleen.validModel(nonEmptyStoryPagesSchema)(newStoryPages)
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

      return Promise.all(newStoryPages.map(storyDBActions.pageExists));
    })
    .then<Collection>((pagesExistArray) => {
      if (!R.all(R.identity, pagesExistArray)) {
        return Promise.reject({
          errorCode: ErrorCode.storyAddingNonExistantTidbit,
          message: "A tidbit you were adding does not exist."
        });
      }

      return collection("stories");
    })
    .then((storyCollection) => {
      return storyCollection.findOneAndUpdate(
        { _id: ID(storyID), author: userID },
        { $push: { pages: { $each: newStoryPages } } },
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
