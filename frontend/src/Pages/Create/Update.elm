module Pages.Create.Update exposing (..)

import Api
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import DefaultServices.Util as Util
import Models.Route as Route
import Pages.Create.Messages exposing (..)
import Pages.Create.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Create` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update { doNothing, justSetShared, justUpdateModel, justProduceCmd } msg model shared =
    case msg of
        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                Route.CreatePage ->
                    case shared.user of
                        -- Should never happen.
                        Nothing ->
                            doNothing

                        Just user ->
                            if Util.isNothing shared.userStories then
                                justProduceCmd <|
                                    Api.getStories
                                        [ ( "author", Just user.id ) ]
                                        OnGetAccountStoriesFailure
                                        OnGetAccountStoriesSuccess
                            else
                                doNothing

                _ ->
                    doNothing

        OnGetAccountStoriesSuccess userStories ->
            justSetShared { shared | userStories = Just userStories }

        OnGetAccountStoriesFailure apiError ->
            -- TODO handle error.
            doNothing

        ShowInfoFor maybeTidbitType ->
            justUpdateModel <| setShowInfoFor maybeTidbitType
