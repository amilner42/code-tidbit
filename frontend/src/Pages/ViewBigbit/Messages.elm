module Pages.ViewBigbit.Messages exposing (..)

import Elements.FileStructure as FS
import Models.ApiError as ApiError
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Range as Range
import Models.Route as Route
import Models.Story as Story


{-| `ViewBigbit` msg.
-}
type Msg
    = NoOp
    | GoTo Route.Route
    | OnRouteHit Route.Route
    | OnGetBigbitFailure ApiError.ApiError
    | OnGetBigbitSuccess Bigbit.Bigbit
    | ViewBigbitToggleFS
    | ViewBigbitToggleFolder FS.Path
    | ViewBigbitSelectFile FS.Path
    | ViewBigbitRangeSelected Range.Range
    | ViewBigbitBrowseRelevantHC
    | ViewBigbitCancelBrowseRelevantHC
    | ViewBigbitNextRelevantHC
    | ViewBigbitPreviousRelevantHC
    | ViewBigbitJumpToFrame Route.Route
    | ViewBigbitGetCompletedSuccess Completed.IsCompleted
    | ViewBigbitGetCompletedFailure ApiError.ApiError
    | ViewBigbitMarkAsComplete Completed.Completed
    | ViewBigbitMarkAsCompleteSuccess Completed.IsCompleted
    | ViewBigbitMarkAsCompleteFailure ApiError.ApiError
    | ViewBigbitMarkAsIncomplete Completed.Completed
    | ViewBigbitMarkAsIncompleteSuccess Completed.IsCompleted
    | ViewBigbitMarkAsIncompleteFailure ApiError.ApiError
    | ViewBigbitGetExpandedStoryFailure ApiError.ApiError
    | ViewBigbitGetExpandedStorySuccess Story.ExpandedStory
