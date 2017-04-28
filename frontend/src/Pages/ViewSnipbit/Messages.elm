module Pages.ViewSnipbit.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Completed exposing (Completed, IsCompleted)
import Models.Range exposing (Range)
import Models.Route exposing (Route)
import Models.Snipbit exposing (Snipbit)
import Models.Story exposing (ExpandedStory)
import Models.Opinion exposing (Opinion, PossibleOpinion)


{-| `ViewSnipbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnGetCompletedSuccess IsCompleted
    | OnGetCompletedFailure ApiError
    | OnGetSnipbitSuccess Snipbit
    | OnGetSnipbitFailure ApiError
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
    | OnRangeSelected Range
    | BrowseRelevantHC
    | CancelBrowseRelevantHC
    | NextRelevantHC
    | PreviousRelevantHC
    | JumpToFrame Route
    | MarkAsComplete Completed
    | OnMarkAsCompleteSuccess IsCompleted
    | OnMarkAsCompleteFailure ApiError
    | MarkAsIncomplete Completed
    | OnMarkAsIncompleteSuccess IsCompleted
    | OnMarkAsIncompleteFailure ApiError
