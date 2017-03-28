module Pages.Profile.Init exposing (..)

import Pages.Profile.Model exposing (..)


{-| `Profile` init.
-}
init : Model
init =
    { accountName = Nothing
    , accountBio = Nothing
    , logOutError = Nothing
    }
