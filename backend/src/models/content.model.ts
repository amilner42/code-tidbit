/// Module for encapsulating helper functions for the content model.

import * as R from "ramda";

import { combineArrays, sortByNewestDate }  from "../util";
import { MongoID } from "../types"
import { Tidbit, tidbitDBActions } from './tidbit.model';
import { Story, storyDBActions } from './story.model';


/**
 * Content represents basically any content that the user creates, used on the browse page.
 */
export type Content = Tidbit | Story;

/**
 * The search options.
 */
export interface ContentSearchFilter {
  author?: MongoID;
}

/**
 * The result manipulation options.
 *
 * NOTE: `pageSize` refers to the pageSize against each individual collection, not the total page size.
 */
export interface ContentResultManipulation {
  sortByLastModified?: boolean;
  pageSize?: number;
  pageNumber?: number;
}

/**
 * All the db helpers for content.
 */
export const contentDBActions = {
  /**
   * Gets content, customizable through the `ContentSearchFilter` and `ContentResultManipulation`.
   */
  getContent: (searchFilter: ContentSearchFilter, resultManipulation: ContentResultManipulation): Promise<Content[]> => {
    return Promise.all([
      tidbitDBActions.getTidbits(searchFilter, resultManipulation),
      storyDBActions.getStories(searchFilter, resultManipulation)
    ])
    .then<Content[]>(([ tidbits, stories ]) => {
      let contentArray = combineArrays(tidbits, stories);

      if(resultManipulation.sortByLastModified) {
        return sortByNewestDate<Content>(R.prop("lastModified"), contentArray);
      }

      return contentArray;
    });
  }
}
