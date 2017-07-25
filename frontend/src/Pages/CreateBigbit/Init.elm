module Pages.CreateBigbit.Init exposing (..)

import Array
import Elements.Simple.FileStructure as FS
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
