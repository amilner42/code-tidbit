module Pages.ViewBigbit.Messages exposing (..)

import Date exposing (Date)
import Elements.Complex.AnswerQuestion as AnswerQuestion
import Elements.Complex.AskQuestion as AskQuestion
import Elements.Complex.EditAnswer as EditAnswer
import Elements.Complex.EditQuestion as EditQuestion
import Elements.Simple.FileStructure as FS
import Models.ApiError exposing (ApiError)
import Models.Bigbit exposing (Bigbit)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.QA exposing (BigbitQA, BigbitCodePointer, BigbitQuestion, Answer)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)
import ProjectTypeAliases exposing (..)


{-| `ViewBigbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | GoToAskQuestionWithCodePointer BigbitID (Maybe BigbitCodePointer)
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
    | EditAnswerMsg BigbitID BigbitQuestion Answer EditAnswer.Msg
    | EditAnswer BigbitID AnswerID AnswerText
    | OnEditAnswerSuccess BigbitID AnswerID AnswerText Date
    | OnEditAnswerFailure ApiError
