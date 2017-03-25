module Pages.Create.Update exposing (..)

import Api
import DefaultServices.Util as Util
import Pages.Create.Messages exposing (..)
import Pages.Create.Model exposing (..)
import Pages.Model exposing (Shared)
import Models.Route as Route


{-| `Create` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )

        justSetShared newShared =
            ( model, newShared, Cmd.none )
    in
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
                                            GetAccountStoriesFailure
                                            GetAccountStoriesSuccess
                                else
                                    doNothing

                    _ ->
                        doNothing

            ShowInfoFor maybeTidbitType ->
                justUpdateModel <| setShowInfoFor maybeTidbitType

            GetAccountStoriesFailure apiError ->
                -- TODO handle error.
                doNothing

            GetAccountStoriesSuccess userStories ->
                justSetShared <|
                    { shared
                        | userStories = Just userStories
                    }