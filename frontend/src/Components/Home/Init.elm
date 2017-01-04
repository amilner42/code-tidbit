module Components.Home.Init exposing (init)

import Components.Home.Model exposing (Model)


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , creatingTidbitType = Nothing
    , creatingBasicTidbitData =
        { language = Nothing
        }
    }
