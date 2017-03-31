/// Module for encapsulating helper functions for the content model.

import { Collection, Cursor } from "mongodb";
import * as R from "ramda";

import { toMongoObjectID, paginateResults } from "../db";
import { combineArrays, sortByNewestDate, isNullOrUndefined, dropNullAndUndefinedProperties, sortByHighestScore }  from "../util";
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
  searchQuery?: string;
}

/**
 * The result manipulation options.
 *
 * NOTE: `pageSize` refers to the pageSize against each individual collection, not the total page size.
 *
 * NOTE: You can only sort by one of the `sortBy...` below.
 *
 * NOTE: You should only `sortByTextScore` if you also search with a `searchQuery, otherwise they all have a score of 0.
 */
export interface ContentResultManipulation {
  sortByLastModified?: boolean;
  sortByTextScore?: boolean;
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
      } else if(resultManipulation.sortByTextScore) {
        return sortByHighestScore<Content>(R.prop("textScore"), contentArray);
      }

      return contentArray;
    });
  }
}

/**
 * For staying DRY for content which uses the default `ContentSearchFilter` and
 * `ContentResultManipulation`.
 */
export const getContent = <Content>
  ( contentCollection: Promise<Collection>,
    filter: ContentSearchFilter,
    resultManipulation: ContentResultManipulation,
    prepareForResponse: (content: Content) => Content | Promise<Content>
  ): Promise<Content[]> => {

  return contentCollection
  .then((collection) => {
    let useLimit = true;
    let cursor: Cursor;

    // Converting author to a `MongoObjectID` and turning off paging.
    if(!isNullOrUndefined(filter.author)) {
      filter.author = toMongoObjectID(filter.author);
      useLimit = false; // We can only avoid limiting results if it's just for one user.
    }

    // Converting search from filter to mongo format.
    if(!isNullOrUndefined(filter.searchQuery)) {
      filter["$text"] = { $search: filter.searchQuery };
      delete filter.searchQuery;
    }

    // We don't want optional fields in the `filter` being included in the search.
    const mongoFindQuery = dropNullAndUndefinedProperties(filter);

    // If we want to sort by text score we need to project meta-text-score onto records.
    if(resultManipulation.sortByTextScore) {
      cursor = collection.find(mongoFindQuery, { textScore: { $meta: "textScore" }});
    } else {
      cursor = collection.find(mongoFindQuery);
    }

    // Sort.
    if(resultManipulation.sortByLastModified) {
      cursor = cursor.sort({ lastModified: -1 });
    } else if(resultManipulation.sortByTextScore) {
      cursor = cursor.sort({ textScore: { $meta: "textScore" }});
    }

    // Paginate.
    if(useLimit) {
      const pageNumber = resultManipulation.pageNumber || 1;
      const pageSize = resultManipulation.pageSize || 10;

      cursor = paginateResults(pageNumber, pageSize, cursor);
    }

    return cursor.toArray();
  })
  .then((arrayOfContent) => {
    return Promise.all(arrayOfContent.map(prepareForResponse));
  });
}
