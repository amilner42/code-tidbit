module Pages.Welcome.Update exposing (update)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import Models.ApiError as ApiError
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.Welcome.Init exposing (..)
import Pages.Welcome.Messages exposing (..)
import Pages.Welcome.Model exposing (..)


{-| `Welcome` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update { justSetModel, justProduceCmd, api } msg model shared =
    case msg of
        -- On top of going to a route, wipes the errors on the welcome page.
        GoTo route ->
            ( wipeError model, shared, Route.navigateTo route )

        OnPasswordInput newPassword ->
            justSetModel <| wipeError { model | password = newPassword }

        OnConfirmPasswordInput newConfirmPassword ->
            justSetModel <| wipeError { model | confirmPassword = newConfirmPassword }

        OnEmailInput newEmail ->
            justSetModel <| wipeError { model | email = newEmail }

        OnNameInput newName ->
            justSetModel <| wipeError { model | name = newName }

        Register ->
            if model.password == model.confirmPassword then
                justProduceCmd <|
                    api.post.register
                        { name = model.name
                        , email = model.email
                        , password = model.password
                        }
                        OnRegisterFailure
                        OnRegisterSuccess
            else
                justSetModel
                    { model | apiError = Just ApiError.PasswordDoesNotMatchConfirmPassword }

        OnRegisterFailure newApiError ->
            justSetModel { model | apiError = Just newApiError }

        OnRegisterSuccess newUser ->
            ( init, { shared | user = Just newUser }, Route.navigateTo Route.BrowsePage )

        Login ->
            justProduceCmd <|
                api.post.login { email = model.email, password = model.password } OnLoginFailure OnLoginSuccess

        OnLoginSuccess newUser ->
            ( init, { shared | user = Just newUser }, Route.navigateTo Route.BrowsePage )

        OnLoginFailure newApiError ->
            justSetModel { model | apiError = Just newApiError }


{-| Sets the `apiError` on the `model` to `Nothing`.
-}
wipeError : Model -> Model
wipeError model =
    { model | apiError = Nothing }
