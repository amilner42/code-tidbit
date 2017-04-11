/// Module for encapsulating helper functions for the content model.

import { Collection, Cursor } from "mongodb";
import * as R from "ramda";

import { toMongoObjectID, paginateResults, collection } from "../db";
import { combineArrays, isNullOrUndefined, dropNullAndUndefinedProperties, getTime, sortByAll, SortOrder }  from "../util";
import { MongoID, MongoObjectID } from "../types"
import { Bigbit, bigbitDBActions } from "./bigbit.model";
import { Snipbit, snipbitDBActions } from "./snipbit.model";
import { Story, storyDBActions, StorySearchFilter } from './story.model';


/**
 * The different content types.
 */
export enum ContentType {
  Snipbit = 1,
  Bigbit,
  Story
}

/**
 * Content represents basically any content that the user creates, used on the browse page.
 */
export type Content = Snipbit | Bigbit | Story;

/**
 * General search configuration which does not apply to each collection individually.
 */
export interface GeneralSearchConfiguration {
  includeSnipbits?: boolean;
  includeBigbits?: boolean;
  includeStories?: boolean;
}

/**
 * The search options (which apply at the collection-level, to each collection).
 */
export interface ContentSearchFilter {
  author?: MongoID;
  searchQuery?: string;
  restrictLanguage?: string;
}

/**
 * The result manipulation options (which apply at the collection-level, to each collection).
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
   * Gets content from the database, customizable through params.
   */
  getContent:
    ( generalSearchConfig: GeneralSearchConfiguration
    , searchFilter: ContentSearchFilter | StorySearchFilter
    , resultManipulation: ContentResultManipulation
    ): Promise<Content[]> => {

    // We don't want to include fields just used on the `StorySearchFilter` for a search on a collection other than the
    // story collection.
    const contentSearchFilter = R.clone(searchFilter);
    delete (contentSearchFilter as StorySearchFilter).includeEmptyStories;

    return Promise.all([
      generalSearchConfig.includeSnipbits ? snipbitDBActions.getSnipbits(contentSearchFilter, resultManipulation) : [],
      generalSearchConfig.includeBigbits ? bigbitDBActions.getBigbits(contentSearchFilter, resultManipulation) : [],
      generalSearchConfig.includeStories ? storyDBActions.getStories(searchFilter, resultManipulation) : []
    ])
    .then<Content[]>(([ snipbits, bigbits, stories ]) => {
      let contentArray = combineArrays(combineArrays(snipbits, bigbits), stories);

      if(resultManipulation.sortByLastModified) {
        return sortByAll<Content>(
          [
            [ SortOrder.Descending, R.prop("lastModified")],
            [ SortOrder.Ascending, R.pipe(R.prop("name"), R.toLower) ]
          ],
          contentArray
        );
      } else if(resultManipulation.sortByTextScore) {

        return sortByAll<Content>(
          [
            [ SortOrder.Descending, R.prop("textScore")],
            [ SortOrder.Ascending, R.pipe(R.prop("name"), R.toLower) ]
          ],
          contentArray
        );
      }

      return contentArray;
    });
  }
}

/**
 * For staying DRY when getting content from the db.
 */
export const getContent = <Content>
  ( contentType: ContentType,
    filter: ContentSearchFilter | StorySearchFilter,
    resultManipulation: ContentResultManipulation,
    prepareForResponse: (content: Content) => Content | Promise<Content>
  ): Promise<Content[]> => {

  let collectionName;
  const mongoQuery: {
    author?: MongoObjectID,
    $text?: { $search: string },
    language?: string,
    languages?: string,
    tidbitPointers?: { $gt: any[] }
  } = {};

  switch(contentType) {
    case ContentType.Snipbit:
      collectionName = "snipbits";
      break;

    case ContentType.Bigbit:
      collectionName = "bigbits";
      break;

    case ContentType.Story:
      collectionName = "stories";
      break;
  }

  return collection(collectionName)
  .then((collection) => {
    let useLimit = true;
    let cursor: Cursor;

    if(!isNullOrUndefined(filter.author)) {
      mongoQuery.author = toMongoObjectID(filter.author);
      useLimit = false; // We can only avoid limiting results if it's just for one user.
    }

    if(!isNullOrUndefined(filter.searchQuery)) {
      mongoQuery.$text = { $search: filter.searchQuery };
    }

    // If we were given a `StorySearchFilter` and it specifically set to not include empty stories, we need to filter
    // those out using mongo `$gt`.
    if(contentType === ContentType.Story && (filter as StorySearchFilter).includeEmptyStories === false) {
      mongoQuery.tidbitPointers = { $gt: [] };
    }

    if(!isNullOrUndefined(filter.restrictLanguage)) {

      switch(contentType) {
        case ContentType.Snipbit:
          mongoQuery.language = filter.restrictLanguage;
          break;

        case ContentType.Bigbit:
          mongoQuery.languages = filter.restrictLanguage;
          break;
      }
    }

    // If we want to sort by text score we need to project meta-text-score onto records.
    if(resultManipulation.sortByTextScore) {
      cursor = collection.find(mongoQuery, { textScore: { $meta: "textScore" }});
    } else {
      cursor = collection.find(mongoQuery);
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
