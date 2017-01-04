module Components.Home.Update exposing (update)

import Api
import Components.Home.Init as HomeInit
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Model exposing (Shared)
import DefaultModel exposing (defaultShared)
import Models.Route as Route
import Router
import Ports


{-| Home Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    case msg of
        GoToBrowseView ->
            ( model
            , shared
            , Router.navigateTo Route.HomeComponentBrowse
            )

        GoToCreateView ->
            ( model
            , shared
            , Router.navigateTo Route.HomeComponentCreate
            )

        GoToProfileView ->
            ( model
            , shared
            , Router.navigateTo Route.HomeComponentProfile
            )

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

        CreateEditor idName ->
            ( model
            , shared
            , Ports.createCodeEditor idName
            )

        SelectTidbitTypeForCreate tidbitType ->
            let
                newModel =
                    { model | creatingTidbitType = tidbitType }
            in
                ( newModel, shared, Cmd.none )
