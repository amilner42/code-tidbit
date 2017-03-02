/// Module for encapsulating helper functions for the story model.

import * as kleen from "kleen";

import { renameIDField } from '../db';
import { malformedFieldError } from '../util';
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
* The schema for validating a StoryPage.
*/
export const storyPageSchema: kleen.typeSchema = {
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
export const storySchema: kleen.typeSchema = {
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
export const newStorySchema: kleen.typeSchema = {
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
