module Components.Home.Init exposing (init)

import Array
import Autocomplete as AC
import Components.Home.Model exposing (Model)
import Elements.Editor as Editor
import Models.BasicTidbit as BasicTidbit


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , creatingBasicTidbitData =
        { language = Nothing
        , languageQueryACState = AC.empty
        , languageListHowManyToShow = (List.length Editor.humanReadableListOfLanguages)
        , languageQuery = ""
        , name = ""
        , description = ""
        , tags = []
        , tagInput = ""
        , code = ""
        , highlightedComments =
            Array.fromList
                [ { comment = Nothing, range = Nothing }
                ]
        , introduction = ""
        , conclusion = ""
        }
    }
