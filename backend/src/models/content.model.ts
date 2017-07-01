/// Module for encapsulating helper functions for the content model.

import { Collection, Cursor } from "mongodb";
import * as R from "ramda";
import * as kleen from "kleen";

import { mongoIDSchema } from "./kleen-schemas";
import { toMongoObjectID, getPaginatedResults, collection } from "../db";
import { combineArrays, isNullOrUndefined, dropNullAndUndefinedProperties, getTime, sortByAll, SortOrder, isBlankString, malformedFieldError }  from "../util";
import { MongoID, MongoObjectID } from "../types"
import { Bigbit, bigbitDBActions } from "./bigbit.model";
import { Snipbit, snipbitDBActions } from "./snipbit.model";
import { Story, storyDBActions, StorySearchFilter } from './story.model';
import { languagesFromWords, stripLanguagesFromWords } from "./language.model";


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
 * A means for referring-to/finding specific content.
 */
export interface ContentPointer {
  contentType: ContentType,
  contentID: MongoID
};

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
  restrictLanguage?: string[];
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
 * For validating a `ContentPointer` has a valid `ContentType` and a valid mongoID (string) for the pointer.
 */
export const contentPointerSchema: kleen.objectSchema = {
  objectProperties: {
    contentType: {
      primitiveType: kleen.kindOfPrimitive.number,
      typeFailureError: malformedFieldError("contentType"),
      restriction: (contentType) => {
        if(!(contentType in ContentType)) return Promise.reject(malformedFieldError("contentType"));
      }
    },
    contentID: mongoIDSchema(malformedFieldError("contentID"))
  },
  typeFailureError: malformedFieldError("contentPointer")
};

/**
 * All the db helpers for content.
 */
export const contentDBActions = {
  /**
   * Gets content from the database, customizable through `GeneralSearchConfiguration` and
   * `ContentSearchFilter | StorySearchFilter` and `ContentResultManipulation`.
   */
  getContent:
    ( generalSearchConfig: GeneralSearchConfiguration
    , filter: ContentSearchFilter | StorySearchFilter
    , resultManipulation: ContentResultManipulation
    ): Promise<[boolean, Content[]]> => {

    // So we don't mutate function parameters.
    const searchFilter = R.clone(filter);

    // If they passed a search query, we want to strip and extract the languages from the query.
    if(searchFilter.searchQuery) {
      // We only set the `restrictLanguage` if the user didn't already set it.
      if(isNullOrUndefined(searchFilter.restrictLanguage) || R.isEmpty(searchFilter.restrictLanguage)) {
        searchFilter.restrictLanguage = languagesFromWords(searchFilter.searchQuery);

        // You can't restrict to 0 languages.
        if(R.isEmpty(searchFilter.restrictLanguage)) {
          delete searchFilter.restrictLanguage;
        }
      }

      // Regardless we strip the languages from the query.
      const searchQueryWithLanguagesStripped = stripLanguagesFromWords(searchFilter.searchQuery);
      if(isBlankString(searchQueryWithLanguagesStripped)) {
        delete searchFilter.searchQuery;
      } else {
        searchFilter.searchQuery = searchQueryWithLanguagesStripped;
      }
    }

    return Promise.all([
      generalSearchConfig.includeSnipbits ? snipbitDBActions.getSnipbits(searchFilter, resultManipulation) : [ false, [] ],
      generalSearchConfig.includeBigbits ? bigbitDBActions.getBigbits(searchFilter, resultManipulation) : [ false, [] ],
      generalSearchConfig.includeStories ? storyDBActions.getStories(searchFilter, resultManipulation) : [ false, [] ]
    ])
    .then<[boolean, Content[]]>((
      [
        [ isMoreSnipbits, snipbits ],
        [ isMoreBigbits, bigbits ],
        [ isMoreStories, stories ]
      ]
    ) => {

      const getSortedContentArray = (): Content[] => {
        let contentArray: Content[] = combineArrays(combineArrays(snipbits, bigbits), stories);

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
      };

        return [isMoreSnipbits || isMoreBigbits || isMoreStories, getSortedContentArray() ];
    });
  },

  /**
   * Returns true if the `contentPointer` is pointing to actual content.
   */
  contentPointerExists: (contentPointer: ContentPointer, doValidation = true): Promise<boolean> => {
    return contentDBActions.expandContentPointer(contentPointer, doValidation)
    .then((content) => {
      return content !== null;
    });
  },

  /**
   * Expands a contentPointer to the actual content. Returns `null` if the contentPointer points to nothing.
   */
  expandContentPointer: (contentPointer: ContentPointer, doValidation = true): Promise<Content> => {
    const contentCollectionName = (() => {
      switch(contentPointer.contentType) {
        case ContentType.Snipbit:
          return "snipbits"

        case ContentType.Bigbit:
          return "bigbits"

        case ContentType.Story:
          return "stories"
      }
    })();

    return (doValidation ? kleen.validModel(contentPointerSchema)(contentPointer) : Promise.resolve())
    .then(() => {
      return collection(contentCollectionName);
    })
    .then((contentCollection) => {
      return contentCollection.findOne({ _id: toMongoObjectID(contentPointer.contentID) })
    })
    .then((content) => {
      if(content) return content;

      return null;
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
  ): Promise<[boolean, Content[]]> => {

  let collectionName;
  const mongoQuery: {
    author?: MongoObjectID,
    $text?: { $search: string },
    language?: { $in: string[] },
    languages?: { $in: string[] },
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
          mongoQuery.language = { $in: filter.restrictLanguage };
          break;

        default:
          mongoQuery.languages = { $in: filter.restrictLanguage };
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

      return getPaginatedResults(pageNumber, pageSize, cursor);
    }

    return cursor.toArray()
    .then((results) => {
      return [false, results];
    });
  })
  .then(([areMoreResults, arrayOfContent]) => {
    return Promise.all(arrayOfContent.map(prepareForResponse))
    .then((readyArrayOfContent) => {
      return [ areMoreResults, readyArrayOfContent ];
    });
  });
}

/**
 * Get's the `language` or `languages` used for certain `content`.
 *
 * @NOTE: Returns an empty array if `content` isn't of type `Content` (null/undefined/other)
 */
export const getLanguages = (content: Content): string[] => {
  if(!isNullOrUndefined((content as Snipbit).language)) {
    return [(content as Snipbit).language];
  }

  if(!isNullOrUndefined((content as Bigbit | Story).languages)) {
    return (content as Bigbit | Story).languages;
  }

  return [];
}

/**
 * Converts the `contentID` to an `ObjectID` so it can be used in search queries.
 */
export const contentPointerToDBQueryForm = ({ contentType, contentID }: ContentPointer): ContentPointer => {
  return { contentType, contentID: toMongoObjectID(contentID) }
}
