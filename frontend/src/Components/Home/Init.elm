module Components.Home.Init exposing (init)

import Array
import Autocomplete as AC
import Components.Home.Model exposing (Model)
import Elements.Editor as Editor
import Models.FileStructure as FS
import Models.Snipbit as Snipbit
import Models.Bigbit as Bigbit


{-| Home Component Init.
-}
init : Model
init =
    { logOutError = Nothing
    , showInfoFor = Nothing
    , viewingSnipbit = Nothing
    , viewingBigbit = Nothing
    , snipbitCreateData =
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
    , bigbitCreateData =
        { name = ""
        , description = ""
        , tags = []
        , tagInput = ""
        , introduction = ""
        , conclusion = ""
        , fs =
            (FS.emptyFS
                { activeFile = Nothing
                , openFS = True
                , actionButtonState = Nothing
                , actionButtonInput = ""
                , actionButtonSubmitConfirmed = False
                }
                { isExpanded = True }
            )
        , highlightedComments =
            Array.fromList
                [ Bigbit.emptyBigbitHighlightCommentForCreate ]
        }
    }
