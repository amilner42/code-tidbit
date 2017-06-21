/// Module for encapsulating helper functions for the QA model.

import * as kleen from "kleen";
import * as moment from "moment";
import { ObjectID } from "mongodb";
import * as R from "ramda";

import { internalError, isNullOrUndefined, malformedFieldError } from '../util';
import { MongoObjectID, MongoID, ErrorCode } from "../types";
import { collection, toMongoObjectID, renameIDField, rejectIfResultNotOK, rejectIfNoneModified, rejectIfNoneMatched, rejectIfNoneUpserted } from "../db";
import { Range } from "./range.model";
import { TidbitPointer, TidbitType, tidbitPointerSchema } from "./tidbit.model";
import { stringInRange, rangeSchema, nonEmptyStringSchema, mongoIDSchema, booleanSchema } from "./kleen-schemas";


/**
 * The general Q&A model, this represent all the data needed to keep track of Q&A for a single `Tidbit`.
 */
export interface QA<CodePointer> {
  _id?: MongoObjectID,
  tidbitID: MongoObjectID,
  tidbitAuthor: MongoObjectID,
  questions: Question<CodePointer>[],
  questionComments: QuestionComment[],
  answers: Answer[],
  answerComments: AnswerComment[]
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
 * A single question about some code in a `Tidbit`.
 */
export interface Question<CodePointer> {
  id: MongoObjectID,
  questionText: string,
  authorID: MongoObjectID,
  authorEmail: string,
  codePointer: CodePointer,
  upvotes: MongoObjectID[] | [boolean, number],
  downvotes: MongoObjectID[] | [boolean, number],
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
  upvotes: MongoObjectID[] | [boolean, number],
  downvotes: MongoObjectID[] | [boolean, number],
  pinned: boolean,
  lastModified: Date,
  createdAt: Date
}

/**
 * A comment on a question.
 */
export interface QuestionComment {
  id: MongoObjectID,
  questionID: MongoObjectID,
  commentText: string,
  authorID: MongoObjectID,
  authorEmail: string,
  lastModified: Date,
  createdAt: Date
}

/**
 * A comment on an answer.
 */
export interface AnswerComment extends QuestionComment {
  answerID: MongoObjectID
}

/**
 * You can upvote/downvote questions and answers.
 */
export enum Vote {
  Upvote = 1,
  Downvote
}

/**
 * Changes the `upvotes`/`downvotes` format from `MongoObjectID[]` -> `[boolean, number]`. The boolean reflects whether
 * the user upvoted/downvoted that `question`/`answer`, the number represents the total `upvotes`/`downvotes`.
 */
const prepareQuestionOrAnswerForResponse = <T1 extends Question<any> | Answer>
  ( userID: MongoObjectID
  , answerOrQuestion: T1
  ): T1 => {

  const copy = R.clone(answerOrQuestion);

  copy.downvotes = [ R.contains<MongoObjectID>(userID, copy.downvotes as MongoObjectID[]), R.length(copy.downvotes) ];
  copy.upvotes = [ R.contains<MongoObjectID>(userID, copy.upvotes as MongoObjectID[]), R.length(copy.upvotes) ];

  return copy;
};

/**
 * Prepares `qa` for the response by:
 *    - renaming id field
 *    - compressing upvotes/downvotes to their short form.
 */
const prepareQAForResponse = <CodePointer>(qa: QA<CodePointer>, userID: MongoObjectID): QA<CodePointer> => {
  const copy = R.clone(qa);

  copy.answers = copy.answers.map(
    R.curry<MongoObjectID, Answer, Answer>(prepareQuestionOrAnswerForResponse)(userID)
  );
  copy.questions = copy.questions.map(
    R.curry<MongoObjectID, Question<CodePointer>, Question<CodePointer>>(prepareQuestionOrAnswerForResponse)(userID)
  );

  return renameIDField(copy);
};

/**
 * All the db helpers for handling QA related tasks.
 */
export const qaDBActions = {
  /**
   * Creates a blank new QA document for the given tidbit.
   *
   * Will only create the new default QA object if one doesn't already exist for that tidbit.
   *
   * Resolves if a new QA document was successfully created.
   */
  newBlankQAForTidbit:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , tidbitAuthor: MongoObjectID
    ) : Promise<void> => {

    return (doValidation ? kleen.validModel(tidbitPointerSchema)(tidbitPointer) : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const tidbitID = toMongoObjectID(tidbitPointer.targetID);

      return collectionX.updateOne(
        { tidbitID },
        { $setOnInsert: defaultQAObject<any>(tidbitID, tidbitAuthor) },
        { upsert: true }
      );
    })
    .then(rejectIfResultNotOK)
    .then((updateWriteOpResult) => {
      if(updateWriteOpResult.matchedCount === 1) {
        return Promise.reject(
          internalError(`You've already created a QA document for tidbit pointer: ${JSON.stringify(tidbitPointer)}`)
        );
      }

      return Promise.resolve(updateWriteOpResult);
    })
    .then(rejectIfNoneUpserted)
    .then(R.always(null));
  },

  /**
   * Get's the QA document for the given tidbit. If the user is not logged in when making the requst, just pass `null`
   * for the `userID`. This action does not require authentication.
   */
  getQAForTidbit: <CodePointer>
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , userID: MongoObjectID
    ): Promise<QA<CodePointer>> => {

    return (doValidation ? kleen.validModel(tidbitPointerSchema)(tidbitPointer) : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.findOne({ tidbitID: toMongoObjectID(tidbitPointer.targetID) });
    })
    .then((qaDocument: QA<CodePointer>) => {
      if(qaDocument) return Promise.resolve(prepareQAForResponse(qaDocument,  userID));

      return Promise.reject(
        internalError(`Could not find QA object for tidbit pointer: ${JSON.stringify(tidbitPointer)}`)
      );
    });
  },

  /**
   * Ask question.
   *
   * Returns the new question if it was added successfully.
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
    ) : Promise<Question<CodePointer>> => {

    // Check all user input: `tidbitPointer`, `codePointer` , and `questionText`.
    const resolveIfValid = (): Promise<any> => {
      // Check `tidbitPointer` and `questionText`
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(questionTextSchema)(questionText),
      ])
      // Check `codePointer` is valid for the given `tidbitPointer`. We do this after we validate the `tidbitPointer`.
      .then(() => {
        return kleen.validModel(codePointerSchema(tidbitPointer.tidbitType))(codePointer);
      });
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
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneModified)
      .then(R.always(prepareQuestionOrAnswerForResponse(authorID, question)));
    });
  },

  /**
   * Edits a question that the user wrote.
   *
   * Returns the new `lastModified` date if the question was edited successfully. This allows the frontend to update
   * the question to match the one in the DB (without having to send the full question over the wire).
   */
  editQuestion: <CodePointer>
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID : MongoID
    , questionText: string
    , codePointer: CodePointer
    , userID: MongoObjectID
    ) : Promise<Date> => {

    // Checks user input: `tidbitPointer`, `questionText`, `questionID`, and `codePointer`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID),
        kleen.validModel(questionTextSchema)(questionText)
      ])
      .then(() => {
        return kleen.validModel(codePointerSchema(tidbitPointer.tidbitType))(codePointer);
      });
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();
      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "questions.id": toMongoObjectID(questionID),
          "questions.authorID": userID
        },
        { $set:
          {
            "questions.$.questionText": questionText,
            "questions.$.codePointer": codePointer,
            "questions.$.lastModified": dateNow
          }
        },
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(dateNow));
    });
  },

  /**
   * Deletes a question created by the user and:
   *  - All question comments
   *  - All question answers
   *  - All comments on question answers
   *
   * Resolves if question and related data were deleted successfully.
   */
  deleteQuestion:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer` and `questionID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID)
      ]);
    };

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "questions.id": toMongoObjectID(questionID),
          "questions.authorID": userID
        },
        { $pull:
          {
            "questions": { id: toMongoObjectID(questionID) },
            "answers": { questionID: toMongoObjectID(questionID) },
            "questionComments": { questionID: toMongoObjectID(questionID) },
            "answerComments": { questionID: toMongoObjectID(questionID) }
          }
        },
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(null));
    });
  },

  /**
   * Rates a question.
   *
   * Resolves if the question exists and the query was successful.
   */
  rateQuestion:
    ( doValidation: boolean
    , vote: Vote
    , tidbitPointer: TidbitPointer
    , questionID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `vote`, `tidbitPointer`, and `questionID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(voteSchema)(vote),
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const updateObject = (() => {
        switch(vote) {
          case Vote.Upvote:
            return { $addToSet: { "questions.$.upvotes": userID }, $pull: { "questions.$.downvotes": userID }};

          case Vote.Downvote:
            return { $addToSet: { "questions.$.downvotes": userID }, $pull: { "questions.$.upvotes": userID }};
        }
      })();

      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID), "questions.id": toMongoObjectID(questionID) },
        updateObject,
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(R.always(null));
  },

  /**
   * Removes a rating that the user made (will remove upvote/downvote).
   *
   * Resolves if the question exists and the query was successful.
   */
  removeQuestionRating:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer` and `questionID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID), "questions.id": toMongoObjectID(questionID) },
        { $pull: { "questions.$.upvotes": userID, "questions.$.downvotes": userID } },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(R.always(null));
  },

  /**
   * Pins/unpins a question, can only be done by the author of the tidbit.
   *
   * Resolves if the user is the author of the tidbit and the question exists and the query was successful.
   */
  pinQuestion:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID: MongoID
    , pin: boolean
    , userID: MongoObjectID
    ) : Promise<void>  => {

    // Checks user input: `tidbitPointer` and `questionID`, and `pin`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID),
        kleen.validModel(booleanSchema(malformedFieldError("pin")))(pin)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          tidbitAuthor: userID,
          "questions.id": toMongoObjectID(questionID)
        },
        { $set: { "questions.$.pinned": pin } },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(R.always(null))
  },

  /**
   * Answer a question.
   *
   * Returns the answer if it was added successfully.
   */
  answerQuestion:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID: MongoID
    , answerText: string
    , authorID: MongoObjectID
    , authorEmail: string
    ) : Promise<Answer> => {

    // Validate user input: `tidbitPointer`, `questionID`, `answerText`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID),
        kleen.validModel(answerTextSchema)(answerText)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();
      const id = new ObjectID();

      const answer: Answer = {
        id,
        answerText,
        authorEmail,
        authorID,
        createdAt: dateNow,
        lastModified: dateNow,
        downvotes: [],
        upvotes: [],
        pinned: false,
        questionID: toMongoObjectID(questionID)
      };

      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID), "questions.id": toMongoObjectID(questionID) },
        { $push: { answers: answer } },
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(prepareQuestionOrAnswerForResponse(authorID, answer)));
    });
  },

  /**
   * Deletes an answer that the user made. Deletes all related comments as well, regardless of author.
   *
   * Resolves if the answer and related data were all deleted successfully.
   */
  deleteAnswer:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , answerID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer` and `answerID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("answerID")))(answerID)
      ]);
    };

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "answers.id": toMongoObjectID(answerID),
          "answers.authorID": userID
        },
        { $pull:
          {
            answers: { id: toMongoObjectID(answerID) },
            answerComments: { answerID: toMongoObjectID(answerID) }
          }
        },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(rejectIfNoneModified)
    .then(R.always(null));
  },

  /**
   * Edits an existing answer that the user wrote.
   *
   * Returns the new `lastModified` date of the answer if the edit was made successfully. This allows the frontend to
   * update the answer to match the one in the DB (without having to send the full answer over the wire).
   */
  editAnswer:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , answerID: MongoID
    , answerText: string
    , userID: MongoObjectID
    ) : Promise<Date> => {

    // Checks user input: `tidbitPointer`, `answerID`, and `answerText`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("answerID")))(answerID),
        kleen.validModel(answerTextSchema)(answerText)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve() )
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();

      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "answers.id": toMongoObjectID(answerID),
          "answers.authorID": userID
        },
        { $set:
            {
              "answers.$.answerText": answerText,
              "answers.$.lastModified": dateNow
            }
        },
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(dateNow));
    });
  },

  /**
   * Rates an answer.
   *
   * Resolves if answer exists and the query was successful.
   */
  rateAnswer:
    ( doValidation: boolean
    , vote: Vote
    , tidbitPointer: TidbitPointer
    , answerID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer`, `vote`, and `answerID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(voteSchema)(vote),
        kleen.validModel(mongoIDSchema(malformedFieldError("answerID")))(answerID)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const updateObject = (() => {
        switch(vote) {
          case Vote.Upvote:
            return { $addToSet: { "answers.$.upvotes": userID }, $pull: { "answers.$.downvotes": userID }};

          case Vote.Downvote:
            return { $addToSet: { "answers.$.downvotes": userID }, $pull: { "answers.$.upvotes": userID }};
        }
      })();

      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID), "answers.id": toMongoObjectID(answerID)  },
        updateObject,
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(R.always(null));
  },

  /**
   * Removes a rating for an answer.
   *
   * Resolves if the answer exists and the query was successful.
   */
  removeAnswerRating:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , answerID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer` and `answerID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("answerID")))(answerID)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType))
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID), "answers.id": toMongoObjectID(answerID) },
        { $pull: { "answers.$.upvotes": userID, "answers.$.downvotes": userID } },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(R.always(null));
  },

  /**
   * Pins/unpins an answer, can only be performed by the author of the tidbit.
   *
   * Resolves if the user is the author of the tidbit and the answer exists and the query was successful.
   */
  pinAnswer:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , answerID: MongoID
    , pin: boolean
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer`, `answerID`, and `pin`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("answerID")))(answerID),
        kleen.validModel(booleanSchema(malformedFieldError("pin")))(pin)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          tidbitAuthor: userID,
          "answers.id": toMongoObjectID(answerID)
        },
        { $set: { "answers.$.pinned": pin } },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(R.always(null));
  },

  /**
   * Adds a comment to the comment thread on a question.
   *
   * Returns the comment if it was added successfully.
   */
  commentOnQuestion:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID: MongoID
    , commentText: string
    , userID: MongoObjectID
    , userEmail: string,
    ) : Promise<QuestionComment> => {

    // Checks user input: `tidbitPointer`, `questionID`, and `commentText`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID),
        kleen.validModel(commentTextSchema)(commentText)
      ]);
    }

    return ( doValidation ? resolveIfValid() : Promise.resolve() )
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();
      const id = new ObjectID();

      const newComment: QuestionComment = {
        id,
        questionID: toMongoObjectID(questionID),
        authorID: userID,
        authorEmail: userEmail,
        commentText,
        createdAt: dateNow,
        lastModified: dateNow
      };

      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID), "questions.id": toMongoObjectID(questionID) },
        { $push: { "questionComments": newComment }},
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(newComment));
    });
  },

  /**
   * Edits a question written by the user.
   *
   * Returns the new `lastModified` date if the question was edited successfully. This allows the frontend to update
   * it's copy of the question comment to match the one in the DB (without having to send it over the wire).
   */
  editQuestionComment:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , commentID: MongoID
    , commentText: string
    , userID: MongoObjectID
    ) : Promise<Date> => {

    // Checks user input: `tidbitPointer`, `commentID`, and `commentText`
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(commentTextSchema)(commentText),
        kleen.validModel(mongoIDSchema(malformedFieldError("commentID")))(commentID)
      ]);
    }

    return ( doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();

      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "questionComments.authorID": userID,
          "questionComments.id": toMongoObjectID(commentID)
        },
        { $set:
          {
            "questionComments.$.lastModified": dateNow,
            "questionComments.$.commentText": commentText
          }
        },
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(dateNow));
    });
  },

  /**
   * Removes a comment on a question that the user made.
   *
   * Resolves if the comment was deleted successfully.
   */
  deleteQuestionComment:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , commentID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer` and `commentID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("commentID")))(commentID)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID) },
        { $pull: { questionComments: { id: toMongoObjectID(commentID), authorID: userID } } },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(rejectIfNoneModified)
    .then(R.always(null));
  },

  /**
   * Comment on an answer.
   *
   * Returns the comment if it was added successfully.
   */
  commentOnAnswer:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , questionID
    , answerID: MongoID
    , commentText: string
    , userID: MongoObjectID
    , userEmail: string
    ) : Promise<AnswerComment> => {

    // Checks user input: `tidbitPointer`, `questionID`, `answerID`, and `commentText`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("questionID")))(questionID),
        kleen.validModel(mongoIDSchema(malformedFieldError("answerID")))(answerID),
        kleen.validModel(commentTextSchema)(commentText)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();
      const id = new ObjectID();

      const newComment: AnswerComment = {
        id,
        authorEmail: userEmail,
        authorID: userID,
        commentText,
        createdAt: dateNow,
        lastModified: dateNow,
        questionID: toMongoObjectID(questionID),
        answerID: toMongoObjectID(answerID)
      };

      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "answers.id": toMongoObjectID(answerID),
          "answers.questionID": toMongoObjectID(questionID),
        },
        { $push: { "answerComments": newComment }},
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(newComment));
    });
  },

  /**
   * Edits a comment on an answer that the user made.
   *
   * Returns the new `lastModified` date if the answer comment was edited successfully. This allows the frontend to
   * update the answer comment to match the DB (without having to send the full answer comment over the wire).
   */
  editAnswerComment:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , commentID: MongoID
    , commentText: string
    , userID: MongoObjectID
    ) : Promise<Date> => {

    // Checks user input: `tidbitPointer`, `commentID`, and `commentText`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("commentID")))(commentID),
        kleen.validModel(commentTextSchema)(commentText)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      const dateNow = moment.utc().toDate();

      return collectionX.updateOne(
        {
          tidbitID: toMongoObjectID(tidbitPointer.targetID),
          "answerComments.id": toMongoObjectID(commentID),
          "answerComments.authorID": userID
        },
        { $set:
          {
            "answerComments.$.commentText": commentText,
            "answerComments.$.lastModified": dateNow
          }
        },
        { upsert: false }
      )
      .then(rejectIfResultNotOK)
      .then(rejectIfNoneMatched)
      .then(rejectIfNoneModified)
      .then(R.always(dateNow));
    });
  },

  /**
   * Deletes an answer that the user made.
   *
   * Resolves if comment was deleted successfully.
   */
  deleteAnswerComment:
    ( doValidation: boolean
    , tidbitPointer: TidbitPointer
    , commentID: MongoID
    , userID: MongoObjectID
    ) : Promise<void> => {

    // Checks user input: `tidbitPointer` and `commentID`.
    const resolveIfValid = (): Promise<any> => {
      return Promise.all([
        kleen.validModel(tidbitPointerSchema)(tidbitPointer),
        kleen.validModel(mongoIDSchema(malformedFieldError("commentID")))(commentID)
      ]);
    }

    return (doValidation ? resolveIfValid() : Promise.resolve())
    .then(() => {
      return collection(qaCollectionName(tidbitPointer.tidbitType));
    })
    .then((collectionX) => {
      return collectionX.updateOne(
        { tidbitID: toMongoObjectID(tidbitPointer.targetID) },
        { $pull: { answerComments: { id: toMongoObjectID(commentID), authorID: userID } } },
        { upsert: false }
      );
    })
    .then(rejectIfResultNotOK)
    .then(rejectIfNoneMatched)
    .then(rejectIfNoneModified)
    .then(R.always(null));
  }
}

/**
 * A default QA object, for when we originally put the empty QA object in the database.
 */
export const defaultQAObject = <CodePointer>
  ( tidbitID: MongoObjectID
  , tidbitAuthor: MongoObjectID
  ): QA<CodePointer> => {

  return {
    tidbitID,
    tidbitAuthor,
    questions: [],
    questionComments: [],
    answers: [],
    answerComments: []
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
  stringInRange("questionText", 1, ErrorCode.internalError, 300, ErrorCode.internalError);

/**
 * The schema for the `answerText` part of an `Answer`.
 */
const answerTextSchema: kleen.primitiveSchema =
  stringInRange("answerText", 1, ErrorCode.internalError, 1000, ErrorCode.internalError);

/**
 * The schema for the `commentText` part of a `QuestionComment`/`AnswerComment`.
 */
const commentTextSchema: kleen.primitiveSchema =
  stringInRange("commentText", 1, ErrorCode.internalError, 300, ErrorCode.internalError);

/**
 * For validifying a bigbit code-pointer.
 *
 * NOTE: Does not validify that the file/range points to an actual file/range.
 */
const bigbitCodePointerSchema: kleen.objectSchema = {
  objectProperties: {
    file: nonEmptyStringSchema(malformedFieldError("codePointer.file"), malformedFieldError("codePointer.file")),
    range: rangeSchema(ErrorCode.internalError)
  },
  typeFailureError: malformedFieldError("codePointer")
};

/**
 * For validifying a `Vote` (must be a number).
 */
const voteSchema: kleen.primitiveSchema = {
  primitiveType: kleen.kindOfPrimitive.number,
  typeFailureError: malformedFieldError("vote"),
  restriction: (vote: number) => {
    if(vote in Vote) return Promise.resolve();

    return Promise.reject(internalError(`Vote must be in the enum, not: ${vote}`));
  }
}

/**
 * Returns the `typeSchema` for the `codePointer` based on the `tidbitType`.
 */
const codePointerSchema = (tidbitType: TidbitType): kleen.typeSchema => {
  switch(tidbitType) {
    case TidbitType.Snipbit:
      return rangeSchema(ErrorCode.internalError);

    case TidbitType.Bigbit:
      return bigbitCodePointerSchema;
  }
}
