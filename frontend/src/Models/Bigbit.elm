module Models.Bigbit exposing (..)

import Array
import DefaultServices.ArrayExtra as ArrayExtra
import Char
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Date
import Dict
import Elements.Editor as Editor
import Elements.FileStructure as FS
import Models.Range as Range
import Models.Route as Route


{-| A Bigbit as seen in the database, with a few extra fields thrown in the FS
to make it easier to render.
-}
type alias Bigbit =
    { name : String
    , description : String
    , tags : List String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure { openFS : Bool } BigbitCreateDataFolderMetadata BigbitCreateDataFileMetadata
    , highlightedComments : Array.Array BigbitHighlightedCommentForPublication
    , author : String
    , id : String
    , createdAt : Date.Date
    , lastModified : Date.Date
    }


{-| Bigbit HighlightedComments for publication.

TODO Rename
-}
type alias BigbitHighlightedCommentForPublication =
    { comment : String
    , range : Range.Range
    , file : FS.Path
    }


{-| The metadata connected to every folder in the FS.

TODO Rename.
-}
type alias BigbitCreateDataFolderMetadata =
    { isExpanded : Bool
    }


{-| The metadata connected to every file in the FS.

TODO rename.
-}
type alias BigbitCreateDataFileMetadata =
    { language : Editor.Language
    }


{-| Checks if an entire fs is open.
-}
isFSOpen : FS.FileStructure { a | openFS : Bool } b c -> Bool
isFSOpen (FS.FileStructure _ { openFS }) =
    openFS


{-| Toggles whether the FS is open.
-}
toggleFS : FS.FileStructure { a | openFS : Bool } b c -> FS.FileStructure { a | openFS : Bool } b c
toggleFS (FS.FileStructure tree fsMetadata) =
    FS.FileStructure
        tree
        { fsMetadata
            | openFS = (not fsMetadata.openFS)
        }


{-| Closes the FS.
-}
closeFS : FS.FileStructure { a | openFS : Bool } b c -> FS.FileStructure { a | openFS : Bool } b c
closeFS (FS.FileStructure tree fsMetadata) =
    FS.FileStructure
        tree
        { fsMetadata
            | openFS = False
        }


{-| Toggles whether a specific folder is expanded or not.
-}
toggleFSFolder : FS.Path -> FS.FileStructure a { b | isExpanded : Bool } c -> FS.FileStructure a { b | isExpanded : Bool } c
toggleFSFolder absolutePath fs =
    FS.updateFolder
        absolutePath
        (\(FS.Folder files folders folderMetadata) ->
            FS.Folder
                files
                folders
                { folderMetadata
                    | isExpanded = not folderMetadata.isExpanded
                }
        )
        fs


{-| The current active path (on view page) determined from the route or the
current comment frame.

-- TODO MOVE
-}
viewPageCurrentActiveFile : Route.Route -> Bigbit -> Maybe FS.Path
viewPageCurrentActiveFile route bigbit =
    case route of
        Route.ViewBigbitIntroductionPage _ _ maybePath ->
            maybePath

        Route.ViewBigbitFramePage _ _ frameNumber maybePath ->
            if Util.isNotNothing maybePath then
                maybePath
            else
                Array.get (frameNumber - 1) bigbit.highlightedComments
                    |> Maybe.map .file

        Route.ViewBigbitConclusionPage _ _ maybePath ->
            maybePath

        _ ->
            Nothing
