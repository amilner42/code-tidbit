module Pages.Create.Messages exposing (..)

import Models.ApiError as ApiError
import Models.Route as Route
import Models.Story as Story
import Models.TidbitType as TidbitType


{-| `Create` msg.
-}
type Msg
    = GoTo Route.Route
    | OnRouteHit Route.Route
    | ShowInfoFor (Maybe TidbitType.TidbitType)
    | GetAccountStoriesFailure ApiError.ApiError
    | GetAccountStoriesSuccess (List Story.Story)
