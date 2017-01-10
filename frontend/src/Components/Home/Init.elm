module Components.Home.Init exposing (init)

import Autocomplete as AC
import Components.Home.Model exposing (Model)


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , creatingTidbitType = Nothing
    , creatingBasicTidbitData =
        { language = Nothing
        , languageQueryACState = AC.empty
        , languageQuery = ""
        }
    }
