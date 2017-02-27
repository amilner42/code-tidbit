/// Module for encapsulating helper functions for the story model.

import * as kleen from "kleen";

import { renameIDField } from '../db';
import { malformedFieldError } from '../util';
import { mongoIDSchema, nameSchema, descriptionSchema, optional } from "./kleen-schemas";
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
export const StoryPageSchema: kleen.typeSchema = {
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
export const StorySchema: kleen.typeSchema = {
  objectProperties: {
    "id": optional(mongoIDSchema(malformedFieldError("story.id"))),
    "author": mongoIDSchema(malformedFieldError("author")),
    "name": nameSchema(ErrorCode.storyNameEmpty, ErrorCode.storyNameTooLong),
    "description": descriptionSchema(ErrorCode.storyDescriptionEmpty),
    "pages": {
      arrayElementType: StoryPageSchema,
      typeFailureError: malformedFieldError("pages")
    },
  }
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
