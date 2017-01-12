module Components.Home.Init exposing (init)

import Autocomplete as AC
import Components.Home.Model exposing (Model)
import Models.BasicTidbit as BasicTidbit


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , creatingBasicTidbitData =
        { language = Nothing
        , languageQueryACState = AC.empty
        , languageQuery = ""
        , name = ""
        , description = ""
        , tags = []
        , tagInput = ""
        }
    }
