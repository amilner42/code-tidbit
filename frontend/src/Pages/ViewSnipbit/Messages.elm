module Pages.ViewSnipbit.Messages exposing (..)

import Date exposing (Date)
import Models.ApiError exposing (ApiError)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Models.Snipbit exposing (Snipbit)
import Models.Story exposing (ExpandedStory)
import Models.QA exposing (SnipbitQA, Question, Answer)
import Models.Opinion exposing (Opinion, PossibleOpinion)
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
    | OnAskQuestionTextInput SnipbitID QuestionText
    | AskQuestionTogglePreviewMarkdown SnipbitID
    | AskQuestion SnipbitID Range QuestionText
    | OnAskQuestionSuccess SnipbitID (Question Range)
    | OnAskQuestionFailure ApiError
    | OnEditQuestionTextInput SnipbitID QuestionID (Question Range) QuestionText
    | EditQuestionTogglePreviewMarkdown SnipbitID QuestionID (Question Range)
    | EditQuestion SnipbitID QuestionID QuestionText Range
    | OnEditQuestionSuccess SnipbitID QuestionID QuestionText Range Date
    | OnEditQuestionFailure ApiError
    | NewAnswerTogglePreviewMarkdown SnipbitID QuestionID
    | NewAnswerToggleShowQuestion SnipbitID QuestionID
    | OnNewAnswerTextInput SnipbitID QuestionID AnswerText
    | AnswerQuestion SnipbitID QuestionID AnswerText
    | OnAnswerQuestionSuccess SnipbitID QuestionID Answer
    | OnAnswerFailure ApiError
    | EditAnswerTogglePreviewMarkdown SnipbitID AnswerID Answer
    | EditAnswerToggleShowQuestion SnipbitID AnswerID Answer
    | OnEditAnswerTextInput SnipbitID AnswerID Answer AnswerText
    | EditAnswer SnipbitID QuestionID AnswerID AnswerText
    | OnEditAnswerSuccess SnipbitID QuestionID AnswerID AnswerText Date
    | OnEditAnswerFailure ApiError
