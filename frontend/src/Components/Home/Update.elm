module Components.Home.Update exposing (update)

import Api
import Components.Home.Init as HomeInit
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Model exposing (Shared)
import DefaultModel exposing (defaultShared)
import Models.Route as Route
import Router


{-| Home Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    case msg of
        GoToMainView ->
            let
                newShared =
                    { shared | route = Route.HomeComponentMain }
            in
                ( model, newShared, Router.navigateTo newShared.route )

        GoToProfileView ->
            let
                newShared =
                    { shared | route = Route.HomeComponentProfile }
            in
                ( model, newShared, Router.navigateTo newShared.route )

        OnDataOneChange newDataOne ->
            let
                newModel =
                    { model
                        | dataOne = newDataOne
                    }
            in
                ( newModel, shared, Cmd.none )

        OnDataTwoChange newDataTwo ->
            let
                newModel =
                    { model
                        | dataTwo = newDataTwo
                    }
            in
                ( newModel, shared, Cmd.none )

        LogOut ->
            ( model, shared, Api.getLogOut OnLogOutFailure OnLogOutSuccess )

        OnLogOutFailure apiError ->
            let
                newModel =
                    { model
                        | logOutError = Just apiError
                    }
            in
                ( newModel, shared, Cmd.none )

        OnLogOutSuccess basicResponse ->
            ( HomeInit.init
            , defaultShared
            , Router.navigateTo Route.WelcomeComponentLogin
            )
