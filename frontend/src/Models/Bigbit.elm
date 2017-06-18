module Models.Bigbit exposing (..)

import Array
import Char
import Date
import DefaultServices.ArrayExtra as ArrayExtra
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Dict
import Elements.Simple.Editor as Editor
import Elements.Simple.FileStructure as FS
import Models.Range as Range


{-| A Bigbit as seen in the database with a few extra fields thrown in the FS to make it easier to render.
-}
type alias Bigbit =
    { name : String
    , description : String
    , tags : List String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure FSMetadata FolderMetadata FileMetadata
    , highlightedComments : Array.Array HighlightedComment
    , author : String
    , authorEmail : String
    , id : String
    , createdAt : Date.Date
    , lastModified : Date.Date
    , languages : List Editor.Language
    , likes : Int
    }


{-| `HighlightedComment`s used in Bigbits.
-}
type alias HighlightedComment =
    { comment : String
    , range : Range.Range
    , file : FS.Path
    }


{-| The metadata connected to the entire FS.
-}
type alias FSMetadata =
    { openFS : Bool }


{-| The metadata connected to every folder in the FS.
-}
type alias FolderMetadata =
    { isExpanded : Bool }


{-| The metadata connected to every file in the FS.
-}
type alias FileMetadata =
    { language : Editor.Language }


{-| Checks if an entire fs is open.
-}
isFSOpen : FS.FileStructure { a | openFS : Bool } b c -> Bool
isFSOpen (FS.FileStructure _ { openFS }) =
    openFS


{-| Toggles whether the FS is open.
-}
toggleFS : FS.FileStructure { a | openFS : Bool } b c -> FS.FileStructure { a | openFS : Bool } b c
toggleFS (FS.FileStructure tree fsMetadata) =
    FS.FileStructure tree { fsMetadata | openFS = not fsMetadata.openFS }


{-| Closes the FS.
-}
closeFS : FS.FileStructure { a | openFS : Bool } b c -> FS.FileStructure { a | openFS : Bool } b c
closeFS (FS.FileStructure tree fsMetadata) =
    FS.FileStructure tree { fsMetadata | openFS = False }


{-| Toggles whether a specific folder is expanded or not.
-}
toggleFSFolder :
    FS.Path
    -> FS.FileStructure a { b | isExpanded : Bool } c
    -> FS.FileStructure a { b | isExpanded : Bool } c
toggleFSFolder absolutePath fs =
    FS.updateFolder
        absolutePath
        (\(FS.Folder files folders folderMetadata) ->
            FS.Folder files folders { folderMetadata | isExpanded = not folderMetadata.isExpanded }
        )
        fs


{-| Get's a highlighted comment at a specific index if it exists.
-}
getHighlightedComment : Int -> Bigbit -> Maybe HighlightedComment
getHighlightedComment frameNumber bigbit =
    Array.get (frameNumber - 1) bigbit.highlightedComments
