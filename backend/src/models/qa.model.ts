/// Module for encapsulating helper functions for the QA model.

import * as kleen from "kleen";

import { internalError, isNullOrUndefined } from '../util';
import { MongoObjectID } from "../types";
import { collection, toMongoObjectID } from "../db";
import { Range } from "./range.model";
import { BigbitHighlightedComment } from "./bigbit.model";
import { TidbitPointer, TidbitType, tidbitPointerSchema } from "./tidbit.model";

/**
 * The general Q&A model, this represent all the data needed to keep track of Q&A for a single `Tidbit`.
 */
export interface QA<CodePointer> {
  _id?: MongoObjectID,
  tidbitID: MongoObjectID,
  questions: Question<CodePointer>[],
  answers: Answer[],
  allQuestionComments: { questionID: MongoObjectID, questionComments: Comment[] }[],
  allAnswerComments: { answerID: MongoObjectID, answerComments: Comment[] }[]
}

/**
 * Corresponds to the `snipbitsQA` collection.
 */
export type SnipbitQA = QA<Range>;

/**
 * Corresponds to the `bigbitsQA` collection.
 */
export type BigbitQA = QA<BigbitHighlightedComment>;

/**
 * A single question about some part of `Tidbit`.
 */
export interface Question<CodePointer> {
  id: MongoObjectID,
  question: string,
  authorID?: string,
  codePointer: CodePointer,
  upvotes: MongoObjectID[],
  downvotes: MongoObjectID[],
  pinned: boolean,
  lastModified: Date,
  createdAt: Date
}

/**
 * An answer to a specific question for the given Tidbit.
 */
export interface Answer {
  id: MongoObjectID,
  questionID: MongoObjectID,
  answer: String,
  authorID: String,
  upvotes: MongoObjectID[],
  downvotes: MongoObjectID[],
  pinned: boolean,
  lastModified: Date,
  createdAt: Date
}

/**
 * A single comment, can be for a question or an answer.
 */
export interface Comment {
  comment: string,
  authorID: MongoObjectID,
  lastModified: Date,
  createdAt: Date
}

/**
 * All the db helpers for handling QA related tasks.
 */
export const qaDBActions = {
  /**
   * Creates a blank new QA object for the given tidbit.
   *
   * Will only create the new default QA object if one doesn't already exist for that tidbit.
   */
  newBlankQAForTidbit: (doValidation: boolean, tidbitPointer: TidbitPointer): Promise<QA<any>> => {
    return (doValidation ? kleen.validModel(tidbitPointerSchema)(tidbitPointer) : Promise.resolve())
    .then(() => {
      const collectionName = (() => {
        switch(tidbitPointer.tidbitType) {
          case TidbitType.Snipbit:
            return "snipbitsQA";

          case TidbitType.Bigbit:
            return "bigbitsQA";
        }
      })();

      return collection(collectionName);
    })
    .then((collectionX) => {
      const tidbitID = toMongoObjectID(tidbitPointer.targetID);

      return collectionX.findOneAndUpdate(
        { tidbitID },
        { $setOnInsert: defaultQAObject(tidbitID) },
        { upsert: true, returnOriginal: false }
      );
    })
    .then((result) => {
      if(isNullOrUndefined(result.value)) {
        return Promise.reject(internalError(`Error adding new QA document for: ${tidbitPointer}`))
      }

      return result.value;
    });
  }
}

/**
 * A default QA object, for when we originally put the empty QA object in the database.
 */
export const defaultQAObject = (tidbitID: MongoObjectID): QA<any> => {
  return {
    tidbitID,
    questions: [],
    allAnswerComments: [],
    allQuestionComments: [],
    answers: []
  }
}
