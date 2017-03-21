module Pages.Welcome.Update exposing (update)

import Api
import Pages.Model exposing (Shared)
import Pages.Welcome.Init as WelcomeInit
import Pages.Welcome.Messages exposing (Msg(..))
import Pages.Welcome.Model exposing (Model)
import Models.ApiError as ApiError
import Models.Route as Route


{-| Welcome Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    case msg of
        OnPasswordInput newPassword ->
            let
                newModel =
                    wipeError
                        { model
                            | password = newPassword
                        }
            in
                ( newModel, shared, Cmd.none )

        OnConfirmPasswordInput newConfirmPassword ->
            let
                newModel =
                    wipeError
                        { model
                            | confirmPassword = newConfirmPassword
                        }
            in
                ( newModel, shared, Cmd.none )

        OnEmailInput newEmail ->
            let
                newModel =
                    wipeError
                        { model
                            | email = newEmail
                        }
            in
                ( newModel, shared, Cmd.none )

        OnNameInput newName ->
            let
                newModel =
                    wipeError
                        { model
                            | name = newName
                        }
            in
                ( newModel, shared, Cmd.none )

        Register ->
            let
                passwordsMatch =
                    model.password == model.confirmPassword

                user =
                    { name = model.name
                    , email = model.email
                    , password = model.password
                    }

                newModelIfPasswordsDontMatch =
                    { model
                        | apiError =
                            Just ApiError.PasswordDoesNotMatchConfirmPassword
                    }
            in
                case passwordsMatch of
                    True ->
                        ( model
                        , shared
                        , Api.postRegister
                            user
                            OnRegisterFailure
                            OnRegisterSuccess
                        )

                    False ->
                        ( newModelIfPasswordsDontMatch, shared, Cmd.none )

        OnRegisterFailure newApiError ->
            let
                newModel =
                    { model
                        | apiError = Just newApiError
                    }
            in
                ( newModel, shared, Cmd.none )

        OnRegisterSuccess newUser ->
            let
                newShared =
                    { shared
                        | user = Just newUser
                        , route = Route.BrowsePage
                    }
            in
                ( WelcomeInit.init, newShared, Route.navigateTo newShared.route )

        Login ->
            let
                user =
                    { email = model.email
                    , password = model.password
                    }
            in
                ( model
                , shared
                , Api.postLogin user OnLoginFailure OnLoginSuccess
                )

        OnLoginSuccess newUser ->
            let
                newShared =
                    { shared
                        | user = Just newUser
                        , route = Route.BrowsePage
                    }
            in
                ( WelcomeInit.init, newShared, Route.navigateTo newShared.route )

        OnLoginFailure newApiError ->
            let
                newModel =
                    { model
                        | apiError = Just newApiError
                    }
            in
                ( newModel, shared, Cmd.none )

        GoToLoginView ->
            ( wipeError model
            , shared
            , Route.navigateTo Route.LoginPage
            )

        GoToRegisterView ->
            ( wipeError model
            , shared
            , Route.navigateTo Route.RegisterPage
            )


{-| Sets the `apiError` on the `model` to `Nothing`.
-}
wipeError : Model -> Model
wipeError model =
    let
        newModel =
            { model
                | apiError = Nothing
            }
    in
        newModel
