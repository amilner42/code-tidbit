module Pages.Create.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Util as Util
import Models.Route as Route
import Pages.Create.Messages exposing (..)
import Pages.Create.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Create` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        OnRouteHit route ->
            case route of
                -- Only fetch user stories if we don't already have them.
                Route.CreatePage ->
                    Util.maybeMapWithDefault
                        (\{ id } ->
                            if Util.isNothing shared.userStories then
                                common.justProduceCmd <|
                                    common.api.get.stories
                                        [ ( "author", Just id ), ( "includeEmptyStories", Just "true" ) ]
                                        OnGetAccountStoriesFailure
                                        (Tuple.second >> OnGetAccountStoriesSuccess)
                            else
                                common.doNothing
                        )
                        common.doNothing
                        shared.user

                _ ->
                    common.doNothing

        OnGetAccountStoriesSuccess userStories ->
            common.justSetShared { shared | userStories = Just userStories }

        OnGetAccountStoriesFailure apiError ->
            common.justSetModalError apiError

        ShowInfoFor maybeTidbitType ->
            common.justUpdateModel <| setShowInfoFor maybeTidbitType
