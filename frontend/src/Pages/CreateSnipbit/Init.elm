module Pages.CreateSnipbit.Init exposing (..)

import Array
import Autocomplete as AC
import Elements.Editor as Editor
import Pages.CreateSnipbit.Model exposing (..)


{-| `CreateSnipbit` init.
-}
init : Model
init =
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
    , previewMarkdown = False
    }