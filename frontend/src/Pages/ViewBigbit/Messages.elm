module Pages.ViewBigbit.Messages exposing (..)

import Elements.Simple.FileStructure as FS
import Elements.Complex.AskQuestion as AskQuestion
import Models.ApiError exposing (ApiError)
import Models.Bigbit exposing (Bigbit)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.QA exposing (BigbitQA, BigbitCodePointer, BigbitQuestion)
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
