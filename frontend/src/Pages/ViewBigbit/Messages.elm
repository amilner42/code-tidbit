module Pages.ViewBigbit.Messages exposing (..)

import Date exposing (Date)
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditAnswer as EditAnswer
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Complex.ViewQuestion as ViewQuestion
import Elements.Simple.FileStructure as FS
import Models.ApiError exposing (ApiError)
import Models.Bigbit exposing (Bigbit)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.QA exposing (BigbitQA, BigbitCodePointer, BigbitQuestion, Answer, QuestionComment, AnswerComment)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)
import ProjectTypeAliases exposing (..)


{-| `ViewBigbit` msg.
-}
type Msg
    = NoOp
    | SetUserNeedsAuthModal String
    | GoTo Route
    | GoToAskQuestionWithCodePointer BigbitID (Maybe BigbitCodePointer)
    | GoToBrowseQuestionsWithCodePointer BigbitID (Maybe BigbitCodePointer)
    | OnRouteHit Route
    | OnRangeSelected Range
    | OnGetBigbitSuccess Bool Bigbit
    | OnGetBigbitFailure ApiError
    | OnGetCompletedSuccess IsCompleted
    | OnGetCompletedFailure ApiError
    | OnGetOpinionSuccess PossibleOpinion
    | OnGetOpinionFailure ApiError
    | AddOpinion Opinion
    | OnAddOpinionSuccess Opinion
    | OnAddOpinionFailure ApiError
    | RemoveOpinion Opinion
    | OnRemoveOpinionSuccess Opinion
    | OnRemoveOpinionFailure ApiError
    | OnGetExpandedStorySuccess ExpandedStory
    | OnGetExpandedStoryFailure ApiError
    | ToggleFS
    | ToggleFolder FS.Path
    | SelectFile FS.Path
    | BrowseRelevantHC
    | CancelBrowseRelevantHC
    | NextRelevantHC
    | PreviousRelevantHC
    | JumpToFrame Route
    | OnMarkAsCompleteSuccess IsCompleted
    | OnMarkAsCompleteFailure ApiError
    | BackToTutorialSpot
    | OnGetQASuccess Bool BigbitQA
    | OnGetQAFailure ApiError
    | AskQuestionMsg BigbitID AskQuestion.Msg
    | AskQuestion BigbitID BigbitCodePointer QuestionText
    | OnAskQuestionSuccess BigbitID BigbitQuestion
    | OnAskQuestionFailure ApiError
    | EditQuestionMsg BigbitID BigbitQuestion EditQuestion.Msg
    | EditQuestion BigbitID QuestionID QuestionText BigbitCodePointer
    | OnEditQuestionSuccess BigbitID QuestionID QuestionText BigbitCodePointer Date
    | OnEditQuestionFailure ApiError
    | AnswerQuestionMsg BigbitID BigbitQuestion AnswerQuestion.Msg
    | AnswerQuestion BigbitID QuestionID AnswerText
    | OnAnswerQuestionSuccess BigbitID QuestionID Answer
    | OnAnswerQuestionFailure ApiError
    | EditAnswerMsg BigbitID Answer EditAnswer.Msg
    | EditAnswer BigbitID AnswerID AnswerText
    | OnEditAnswerSuccess BigbitID AnswerID AnswerText Date
    | OnEditAnswerFailure ApiError
    | ViewQuestionMsg BigbitID QuestionID ViewQuestion.Msg
    | ClickUpvoteQuestion BigbitID QuestionID
    | OnClickUpvoteQuestionSuccess QuestionID
    | OnClickUpvoteQuestionFailure ApiError
    | ClickRemoveUpvoteQuestion BigbitID QuestionID
    | OnClickRemoveUpvoteQuestionSuccess QuestionID
    | OnClickRemoveUpvoteQuestionFailure ApiError
    | ClickDownvoteQuestion BigbitID QuestionID
    | OnClickDownvoteQuestionSuccess QuestionID
    | OnClickDownvoteQuestionFailure ApiError
    | ClickRemoveDownvoteQuestion BigbitID QuestionID
    | OnClickRemoveDownvoteQuestionSuccess QuestionID
    | OnClickRemoveDownvoteQuestionFailure ApiError
    | ClickUpvoteAnswer BigbitID AnswerID
    | OnClickUpvoteAnswerSuccess AnswerID
    | OnClickUpvoteAnswerFailure ApiError
    | ClickRemoveUpvoteAnswer BigbitID AnswerID
    | OnClickRemoveUpvoteAnswerSuccess AnswerID
    | OnClickRemoveUpvoteAnswerFailure ApiError
    | ClickDownvoteAnswer BigbitID AnswerID
    | OnClickDownvoteAnswerSuccess AnswerID
    | OnClickDownvoteAnswerFailure ApiError
    | ClickRemoveDownvoteAnswer BigbitID AnswerID
    | OnClickRemoveDownvoteAnswerSuccess AnswerID
    | OnClickRemoveDownvoteAnswerFailure ApiError
    | ClickPinQuestion BigbitID QuestionID
    | OnClickPinQuestionSuccess QuestionID
    | OnClickPinQuestionFailure ApiError
    | ClickUnpinQuestion BigbitID QuestionID
    | OnClickUnpinQuestionSuccess QuestionID
    | OnClickUnpinQuestionFailure ApiError
    | ClickPinAnswer BigbitID AnswerID
    | OnClickPinAnswerSuccess AnswerID
    | OnClickPinAnswerFailure ApiError
    | ClickUnpinAnswer BigbitID AnswerID
    | OnClickUnpinAnswerSuccess AnswerID
    | OnClickUnpinAnswerFailure ApiError
    | DeleteAnswer BigbitID QuestionID AnswerID
    | OnDeleteAnswerSuccess BigbitID QuestionID AnswerID
    | OnDeleteAnswerFailure ApiError
    | SubmitCommentOnQuestion BigbitID QuestionID CommentText
    | OnSubmitCommentOnQuestionSuccess BigbitID QuestionID QuestionComment
    | OnSubmitCommentOnQuestionFailure ApiError
    | SubmitCommentOnAnswer BigbitID QuestionID AnswerID CommentText
    | OnSubmitCommentOnAnswerSuccess BigbitID QuestionID AnswerID AnswerComment
    | OnSubmitCommentOnAnswerFailure ApiError
    | DeleteCommentOnQuestion BigbitID CommentID
    | OnDeleteCommentOnQuestionSuccess BigbitID CommentID
    | OnDeleteCommentOnQuestionFailure ApiError
    | DeleteCommentOnAnswer BigbitID CommentID
    | OnDeleteCommentOnAnswerSuccess BigbitID CommentID
    | OnDeleteCommentOnAnswerFailure ApiError
    | EditCommentOnQuestion BigbitID CommentID CommentText
    | OnEditCommentOnQuestionSuccess BigbitID CommentID CommentText Date
    | OnEditCommentOnQuestionFailure ApiError
    | EditCommentOnAnswer BigbitID CommentID CommentText
    | OnEditCommentOnAnswerSuccess BigbitID CommentID CommentText Date
    | OnEditCommentOnAnswerFailure ApiError
