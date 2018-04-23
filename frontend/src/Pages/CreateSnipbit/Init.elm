module Pages.CreateSnipbit.Init exposing (..)

import Array
import Autocomplete as AC
import Elements.Simple.Editor exposing (humanReadableListOfLanguages)
import Pages.CreateSnipbit.Model exposing (..)


{-| `CreateSnipbit` init.
-}
init : Model
init =
    { language = Nothing
    , languageQueryACState = AC.empty
    , languageListHowManyToShow = List.length humanReadableListOfLanguages
    , languageQuery = ""
    , name = ""
    , description = ""
    , tags = []
    , tagInput = ""
    , code = ""
    , highlightedComments = Array.fromList [ { comment = Nothing, range = Nothing } ]
    , introduction = ""
    , conclusion = ""
    , previewMarkdown = False
    , confirmedRemoveFrame = False
    , confirmedReset = False
    , codeLocked = False
    }
