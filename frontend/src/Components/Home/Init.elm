module Components.Home.Init exposing (init)

import Array
import Autocomplete as AC
import Components.Home.Model exposing (Model)
import Elements.Editor as Editor
import Models.Snipbit as Snipbit


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , showInfoFor = Nothing
    , creatingSnipbitData =
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
