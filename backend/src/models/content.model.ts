/// Module for encapsulating helper functions for the content model.

import { Collection, Cursor } from "mongodb";
import * as R from "ramda";

import { toMongoObjectID, paginateResults } from "../db";
import { combineArrays, isNullOrUndefined, dropNullAndUndefinedProperties, getTime, sortByAll, SortOrder }  from "../util";
import { MongoID } from "../types"
import { Bigbit, bigbitDBActions } from "./bigbit.model";
import { Snipbit, snipbitDBActions } from "./snipbit.model";
import { Story, storyDBActions, StorySearchFilter } from './story.model';


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
  ( contentCollection: Promise<Collection>,
    filter: ContentSearchFilter | StorySearchFilter,
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

    // If we were given a `StorySearchFilter` and it specifically set to not include empty stories, we need to filter
    // those out using mongo `$gt`.
    if((filter as StorySearchFilter).includeEmptyStories === false) {
      filter["tidbitPointers"] = { $gt: [] };
    }
    // We don't want this field on our mongo query.
    delete (filter as StorySearchFilter).includeEmptyStories;

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
