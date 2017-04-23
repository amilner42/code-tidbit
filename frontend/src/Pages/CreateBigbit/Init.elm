module Pages.CreateBigbit.Init exposing (..)

import Array
import Autocomplete as AC
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Pages.CreateBigbit.Model exposing (..)


{-| `CreateBigbit` init.
-}
init : Model
init =
    { name = ""
    , description = ""
    , tags = []
    , tagInput = ""
    , introduction = ""
    , conclusion = ""
    , fs =
        FS.emptyFS
            { activeFile = Nothing
            , openFS = True
            , actionButtonState = Nothing
            , actionButtonInput = ""
            , actionButtonSubmitConfirmed = False
            }
            { isExpanded = True }
    , highlightedComments = Array.fromList [ emptyHighlightCommentForCreate ]
    , previewMarkdown = False
    }


{-| Creates an empty highlighted comment.
-}
emptyHighlightCommentForCreate : HighlightedCommentForCreate
emptyHighlightCommentForCreate =
    { comment = ""
    , fileAndRange = Nothing
    }
