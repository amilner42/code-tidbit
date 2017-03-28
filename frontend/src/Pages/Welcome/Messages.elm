module Pages.Welcome.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Route exposing (Route)
import Models.User exposing (User)


{-| `Welcome` msg.
-}
type Msg
    = GoTo Route
    | Register
    | OnRegisterSuccess User
    | OnRegisterFailure ApiError
    | Login
    | OnLoginSuccess User
    | OnLoginFailure ApiError
    | OnPasswordInput String
    | OnConfirmPasswordInput String
    | OnEmailInput String
    | OnNameInput String
