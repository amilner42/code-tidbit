module Pages.Create.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import DefaultServices.Util as Util
import Models.Route as Route
import Pages.Create.Messages exposing (..)
import Pages.Create.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Create` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update { doNothing, justSetShared, justUpdateModel, justProduceCmd, api, justSetModalError } msg model shared =
    case msg of
        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                -- Only fetch user stories if we don't already have them.
                Route.CreatePage ->
                    Util.maybeMapWithDefault
                        (\{ id } ->
                            if Util.isNothing shared.userStories then
                                justProduceCmd <|
                                    api.get.stories
                                        [ ( "author", Just id ), ( "includeEmptyStories", Just "true" ) ]
                                        OnGetAccountStoriesFailure
                                        OnGetAccountStoriesSuccess
                            else
                                doNothing
                        )
                        doNothing
                        shared.user

                _ ->
                    doNothing

        OnGetAccountStoriesSuccess userStories ->
            justSetShared { shared | userStories = Just userStories }

        OnGetAccountStoriesFailure apiError ->
            justSetModalError apiError

        ShowInfoFor maybeTidbitType ->
            justUpdateModel <| setShowInfoFor maybeTidbitType
