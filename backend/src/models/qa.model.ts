/// Module for encapsulating helper functions for the QA model.

import * as kleen from "kleen";
import * as moment from "moment";
import { ObjectID } from "mongodb";

import { internalError, isNullOrUndefined, malformedFieldError } from '../util';
import { MongoObjectID, ErrorCode } from "../types";
import { collection, toMongoObjectID, renameIDField } from "../db";
import { Range } from "./range.model";
import { TidbitPointer, TidbitType, tidbitPointerSchema } from "./tidbit.model";
import { stringInRange, rangeSchema, nonEmptyStringSchema } from "./kleen-schemas";


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
export type BigbitQA = QA<{ file: string, range: Range }>;

/**
 * A single question about some part of `Tidbit`.
 */
export interface Question<CodePointer> {
  id: MongoObjectID,
  questionText: string,
  authorID: MongoObjectID,
  authorEmail: string,
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
  answerText: String,
  authorID: MongoObjectID,
  authorEmail: string,
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
 * Prepares `qa` for the response by:
 *    - renaming id field
 */
const prepareQAForResponse = (qa: QA<any>) => {
  return renameIDField(qa);
}

/**
 * All the db helpers for handling QA related tasks.
 */
export const qaDBActions = {
  /**
   * Creates a blank new QA document for the given tidbit.
   *
   * Will only create the new default QA object if one doesn't already exist for that tidbit.
   */
  newBlankQAForTidbit: (doValidation: boolean, tidbitPointer: TidbitPointer): Promise<QA<any>> => {
    return (doValidation ? kleen.validModel(tidbitPointerSchema)(tidbitPointer) : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
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
        return Promise.reject(internalError(`Error adding new QA document for: ${JSON.stringify(tidbitPointer)}`));
      }

      return result.value;
    });
  },

  /**
   * Get's the QA document for the given tidbit.
   */
  getQAForTidbit: <CodePointer>(doValidation: boolean, tidbitPointer: TidbitPointer): Promise<QA<CodePointer>> => {
    return (doValidation ? kleen.validModel(tidbitPointerSchema)(tidbitPointer) : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.findOne({ tidbitID: toMongoObjectID(tidbitPointer.targetID) });
    })
    .then((qaDocument) => {
      if(qaDocument) {
        return prepareQAForResponse(qaDocument);
      }

      return Promise.reject(
        internalError(`Could not find QA object for tidbit pointer: ${JSON.stringify(tidbitPointer)}`)
      );
    });
  },

  /**
   * Ask question.
   *
   * TODO: Currently the validation does not check that the CodePointer points to actual code, it simply checks that
   *       everything is structurally correct (types). It would take an extra query to the db to retrieve the object
   *       first if we wanted to validate that the `codePointer` points to something meaningful.
   */
  askQuestion: <CodePointer>
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionText: string
    , codePointer: CodePointer
    , authorID: MongoObjectID
    , authorEmail: string
    ) : Promise<boolean> => {

    // Check all user input: `tidbitPointer`, `codePointer` , and `question`.
    const resolveIfValid = (): Promise<any> => {
      // Check `tidbitPointer` and `questionText`
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(questionTextSchema)(questionText),
      ])
      // Check `codePointer` is valid for the given `tidbitPointer`. We do this after we validate the `tidbitPointer`.
      .then(() => {
        switch(tidbitPointer.tidbitType) {
          case TidbitType.Snipbit:
            return kleen.validModel(rangeSchema(ErrorCode.internalError))(codePointer)

          case TidbitType.Bigbit:
            return kleen.validModel(bigbitCodePointerSchema)(codePointer)
        }
      })
    };

    return ( doValidation ? resolveIfValid() : Promise.resolve() )
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();
      const id = new ObjectID();

      const question: Question<CodePointer> = {
        id,
        authorID,
        authorEmail,
        codePointer,
        downvotes: [],
        upvotes: [],
        createdAt: dateNow,
        lastModified: dateNow,
        pinned: false,
        questionText
      };

      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID) },
        { $push: { questions: question } },
        { upsert: false }
      );
    })
    .then((result) => {
      if(result.modifiedCount === 1) {
        return true;
      }

      return false;
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
};

/**
 * Get's the QA collection name for the given tidbit type.
 */
const qaCollectionName = (tidbitType: TidbitType) => {
  switch(tidbitType) {
    case TidbitType.Snipbit:
      return "snipbitsQA";

    case TidbitType.Bigbit:
      return "bigbitsQA";
  }
};

/**
 * The schema for the `questionText` part of a `Question`.
 */
const questionTextSchema: kleen.primitiveSchema =
  stringInRange("question", 1, ErrorCode.internalError, 300, ErrorCode.internalError);

/**
 * For validifying a bigbit code-pointer.
 *
 * NOTE: Does not validify that the file/range points to an actual file/range.
 */
const bigbitCodePointerSchema: kleen.objectSchema = {
  objectProperties: {
    file: nonEmptyStringSchema(malformedFieldError("file"), malformedFieldError("file")),
    range: rangeSchema(ErrorCode.internalError)
  },
  typeFailureError: malformedFieldError("codePointer")
};
