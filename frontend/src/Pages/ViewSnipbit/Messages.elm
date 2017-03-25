module Pages.ViewSnipbit.Messages exposing (..)

import Models.Range as Range
import Models.Completed as Completed
import Models.ApiError as ApiError
import Models.Story as Story
import Models.Snipbit as Snipbit
import Models.Route as Route


{-| `ViewSnipbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route.Route
    | OnRouteHit Route.Route
    | OnGetSnipbitFailure ApiError.ApiError
    | OnGetSnipbitSuccess Snipbit.Snipbit
    | ViewSnipbitRangeSelected Range.Range
    | ViewSnipbitBrowseRelevantHC
    | ViewSnipbitCancelBrowseRelevantHC
    | ViewSnipbitNextRelevantHC
    | ViewSnipbitPreviousRelevantHC
    | ViewSnipbitJumpToFrame Route.Route
    | ViewSnipbitGetCompletedSuccess Completed.IsCompleted
    | ViewSnipbitGetCompletedFailure ApiError.ApiError
    | ViewSnipbitMarkAsComplete Completed.Completed
    | ViewSnipbitMarkAsCompleteSuccess Completed.IsCompleted
    | ViewSnipbitMarkAsCompleteFailure ApiError.ApiError
    | ViewSnipbitMarkAsIncomplete Completed.Completed
    | ViewSnipbitMarkAsIncompleteSuccess Completed.IsCompleted
    | ViewSnipbitMarkAsIncompleteFailure ApiError.ApiError
    | ViewSnipbitGetExpandedStoryFailure ApiError.ApiError
    | ViewSnipbitGetExpandedStorySuccess Story.ExpandedStory
