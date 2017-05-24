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
import ProjectTypeAliases exposing (..)


{-| `ViewSnipbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route
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
    | JumpToFrame Route
    | OnMarkAsCompleteSuccess IsCompleted
    | OnMarkAsCompleteFailure ApiError
    | GoToAskQuestion
    | GoToBrowseQuestions
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
    | OnClickUpvoteQuestion SnipbitID QuestionID
    | OnClickRemoveQuestionUpvote SnipbitID QuestionID
    | OnClickDownvoteQuestion SnipbitID QuestionID
    | OnClickRemoveQuestionDownvote SnipbitID QuestionID
    | OnUpvoteQuestionSuccess QuestionID
    | OnUpvoteQuestionFailure ApiError
    | OnRemoveQuestionUpvoteSuccess QuestionID
    | OnRemoveQuestionUpvoteFailure ApiError
    | OnDownvoteQuestionSuccess QuestionID
    | OnDownvoteQuestionFailure ApiError
    | OnRemoveQuestionDownvoteSuccess QuestionID
    | OnRemoveQuestionDownvoteFailure ApiError
    | OnClickUpvoteAnswer SnipbitID AnswerID
    | OnClickRemoveAnswerUpvote SnipbitID AnswerID
    | OnClickDownvoteAnswer SnipbitID AnswerID
    | OnClickRemoveAnswerDownvote SnipbitID AnswerID
    | OnUpvoteAnswerSuccess AnswerID
    | OnUpvoteAnswerFailure ApiError
    | OnRemoveAnswerUpvoteSuccess AnswerID
    | OnRemoveAnswerUpvoteFailure ApiError
    | OnDownvoteAnswerSuccess AnswerID
    | OnDownvoteAnswerFailure ApiError
    | OnRemoveAnswerDownvoteSuccess AnswerID
    | OnRemoveAnswerDownvoteFailure ApiError
    | AskQuestionMsg SnipbitID AskQuestion.Msg
    | EditQuestionMsg SnipbitID (Question Range) EditQuestion.Msg
    | AnswerQuestionMsg SnipbitID (Question Range) AnswerQuestion.Msg
    | EditAnswerMsg SnipbitID AnswerID (Question Range) Answer EditAnswer.Msg
    | PinQuestion SnipbitID QuestionID
    | OnPinQuestionSuccess SnipbitID QuestionID
    | OnPinQuestionFailure ApiError
    | UnpinQuestion SnipbitID QuestionID
    | OnUnpinQuestionSuccess SnipbitID QuestionID
    | OnUnpinQuestionFailure ApiError
    | PinAnswer SnipbitID AnswerID
    | OnPinAnswerSuccess SnipbitID AnswerID
    | OnPinAnswerFailure ApiError
    | UnpinAnswer SnipbitID AnswerID
    | OnUnpinAnswerSuccess SnipbitID AnswerID
    | OnUnpinAnswerFailure ApiError
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
