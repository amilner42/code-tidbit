module Pages.NewStory.Messages exposing (..)

import Models.ApiError as ApiError
import Models.IDResponse as IDResponse
import Models.Story as Story
import Models.Route as Route


{-| `NewStory` msg.
-}
type Msg
    = NoOp
    | GoTo Route.Route
    | OnRouteHit Route.Route
    | NewStoryUpdateName String
    | NewStoryEditingUpdateName String
    | NewStoryUpdateDescription String
    | NewStoryEditingUpdateDescription String
    | NewStoryUpdateTagInput String
    | NewStoryEditingUpdateTagInput String
    | NewStoryAddTag String
    | NewStoryEditingAddTag String
    | NewStoryRemoveTag String
    | NewStoryEditingRemoveTag String
    | NewStoryReset
    | NewStoryPublish
    | NewStoryPublishSuccess IDResponse.IDResponse
    | NewStoryPublishFailure ApiError.ApiError
    | NewStoryGetEditingStoryFailure ApiError.ApiError
    | NewStoryGetEditingStorySuccess Story.Story
    | NewStoryCancelEdits String
    | NewStorySaveEdits String
    | NewStorySaveEditsFailure ApiError.ApiError
    | NewStorySaveEditsSuccess IDResponse.IDResponse
