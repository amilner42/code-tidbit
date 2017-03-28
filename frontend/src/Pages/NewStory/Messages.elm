module Pages.NewStory.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.IDResponse exposing (IDResponse)
import Models.Route exposing (Route)
import Models.Story exposing (Story)


{-| `NewStory` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnGetEditingStorySuccess Story
    | OnGetEditingStoryFailure ApiError
    | OnUpdateName String
    | OnEditingUpdateName String
    | OnUpdateDescription String
    | OnEditingUpdateDescription String
    | OnUpdateTagInput String
    | OnEditingUpdateTagInput String
    | AddTag String
    | EditingAddTag String
    | RemoveTag String
    | EditingRemoveTag String
    | Reset
    | Publish
    | OnPublishSuccess IDResponse
    | OnPublishFailure ApiError
    | CancelEdits String
    | SaveEdits String
    | OnSaveEditsSuccess IDResponse
    | OnSaveEditsFailure ApiError
