module Pages.ViewSnipbit.Messages exposing (..)

import Date exposing (Date)
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditAnswer as EditAnswer
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Complex.ViewQuestion as ViewQuestion
import Models.ApiError exposing (ApiError)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.QA exposing (SnipbitQA, Question, Answer, QuestionComment, AnswerComment)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Models.Snipbit exposing (Snipbit)
import Models.Story exposing (ExpandedStory)
import Models.Vote exposing (Vote)
import ProjectTypeAliases exposing (..)


{-| `ViewSnipbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | GoToAskQuestion
    | GoToBrowseQuestionsWithCodePointer (Maybe Range)
    | OnRouteHit Route
    | OnGetCompletedSuccess IsCompleted
    | OnGetCompletedFailure ApiError
    | OnGetSnipbitSuccess Bool Snipbit
    | OnGetSnipbitFailure ApiError
    | OnGetOpinionSuccess PossibleOpinion
    | OnGetOpinionFailure ApiError
    | OnGetQAFailure ApiError
    | OnGetQASuccess Bool SnipbitQA
    | AddOpinion Opinion
    | OnAddOpinionSuccess Opinion
    | OnAddOpinionFailure ApiError
    | RemoveOpinion Opinion
    | OnRemoveOpinionSuccess Opinion
    | OnRemoveOpinionFailure ApiError
    | OnGetExpandedStorySuccess ExpandedStory
    | OnGetExpandedStoryFailure ApiError
    | OnRangeSelected Range
    | BrowseRelevantHC
    | CancelBrowseRelevantHC
    | NextRelevantHC
    | PreviousRelevantHC
    | OnMarkAsCompleteSuccess IsCompleted
    | OnMarkAsCompleteFailure ApiError
    | AskQuestion SnipbitID Range QuestionText
    | OnAskQuestionSuccess SnipbitID (Question Range)
    | OnAskQuestionFailure ApiError
    | EditQuestion SnipbitID QuestionID QuestionText Range
    | OnEditQuestionSuccess SnipbitID QuestionID QuestionText Range Date
    | OnEditQuestionFailure ApiError
    | AnswerQuestion SnipbitID QuestionID AnswerText
    | OnAnswerQuestionSuccess SnipbitID QuestionID Answer
    | OnAnswerFailure ApiError
    | EditAnswer SnipbitID QuestionID AnswerID AnswerText
    | OnEditAnswerSuccess SnipbitID QuestionID AnswerID AnswerText Date
    | OnEditAnswerFailure ApiError
    | DeleteAnswer SnipbitID QuestionID AnswerID
    | OnDeleteAnswerSuccess SnipbitID QuestionID AnswerID
    | OnDeleteAnswerFailure ApiError
    | RateQuestion SnipbitID QuestionID (Maybe Vote)
    | OnRateQuestionSuccess QuestionID (Maybe Vote)
    | OnRateQuestionFailure ApiError
    | RateAnswer SnipbitID AnswerID (Maybe Vote)
    | OnRateAnswerSuccess AnswerID (Maybe Vote)
    | OnRateAnswerFailure ApiError
    | AskQuestionMsg SnipbitID AskQuestion.Msg
    | EditQuestionMsg SnipbitID (Question Range) EditQuestion.Msg
    | AnswerQuestionMsg SnipbitID (Question Range) AnswerQuestion.Msg
    | EditAnswerMsg SnipbitID AnswerID Answer EditAnswer.Msg
    | PinQuestion SnipbitID QuestionID Bool
    | OnPinQuestionSuccess QuestionID Bool
    | OnPinQuestionFailure ApiError
    | PinAnswer SnipbitID AnswerID Bool
    | OnPinAnswerSuccess AnswerID Bool
    | OnPinAnswerFailure ApiError
    | ViewQuestionMsg SnipbitID QuestionID ViewQuestion.Msg
    | SubmitCommentOnQuestion SnipbitID QuestionID CommentText
    | OnSubmitCommentOnQuestionSuccess SnipbitID QuestionID QuestionComment
    | OnSubmitCommentOnQuestionFailure ApiError
    | SubmitCommentOnAnswer SnipbitID QuestionID AnswerID CommentText
    | SubmitCommentOnAnswerSuccess SnipbitID QuestionID AnswerID AnswerComment
    | SubmitCommentOnAnswerFailure ApiError
    | DeleteCommentOnQuestion SnipbitID CommentID
    | OnDeleteCommentOnQuestionSuccess SnipbitID CommentID
    | OnDeleteCommentOnQuestionFailure ApiError
    | DeleteCommentOnAnswer SnipbitID CommentID
    | OnDeleteCommentOnAnswerSuccess SnipbitID CommentID
    | OnDeleteCommentOnAnswerFailure ApiError
    | EditCommentOnQuestion SnipbitID CommentID CommentText
    | OnEditCommentOnQuestionSuccess SnipbitID CommentID CommentText Date.Date
    | OnEditCommentOnQuestionFailure ApiError
    | EditCommentOnAnswer SnipbitID CommentID CommentText
    | OnEditCommentOnAnswerSuccess SnipbitID CommentID CommentText Date.Date
    | OnEditCommentOnAnswerFailure ApiError
    | SetUserNeedsAuthModal String
