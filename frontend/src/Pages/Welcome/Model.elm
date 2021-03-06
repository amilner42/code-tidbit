module Pages.Welcome.Model exposing (..)

import Models.ApiError exposing (ApiError)


{-| `Welcome` model.
-}
type alias Model =
    { name : String
    , email : String
    , password : String
    , confirmPassword : String
    , apiError : Maybe ApiError
    }
