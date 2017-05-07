module Pages.ViewBigbit.Messages exposing (..)

import Elements.FileStructure as FS
import Models.ApiError exposing (ApiError)
import Models.Bigbit exposing (Bigbit)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)


{-| `ViewBigbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnRangeSelected Range
    | OnGetBigbitSuccess Bigbit
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
