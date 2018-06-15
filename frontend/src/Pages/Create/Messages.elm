module Pages.Create.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Route exposing (Route)
import Models.Story exposing (Story)
import Models.TidbitType exposing (TidbitType)


{-| `Create` msg.
-}
type Msg
    = OnRouteHit Route
    | OnGetAccountStoriesSuccess (List Story)
    | OnGetAccountStoriesFailure ApiError
    | ShowInfoFor (Maybe TidbitType)
