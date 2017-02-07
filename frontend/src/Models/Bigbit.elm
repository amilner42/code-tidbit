module Models.Bigbit exposing (..)

import Array
import Char
import DefaultServices.Util as Util
import Dict
import Elements.Editor as Editor
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.HighlightedComment as HighlightedComment
import Models.FileStructure as FS
import Models.Range as Range
import Models.Route as Route


{-| A Bigbit as seen in the database.
-}
type alias Bigbit =
    { name : String
    , description : String
    , tags : List String
    }


{-| Basic union to keep track of the current state of the action buttons in
the file structure.
-}
type FSActionButtonState
    = AddingFolder
    | AddingFile
    | RemovingFolder
    | RemovingFile


{-| FSActionButtonState `cacheEncoder`.
-}
fsActionButtonStateCacheEncoder : FSActionButtonState -> Encode.Value
fsActionButtonStateCacheEncoder =
    toString >> Encode.string


{-| FSActionButtonState `cacheDecoder`.
-}
fsActionButtonStateCacheDecoder : Decode.Decoder FSActionButtonState
fsActionButtonStateCacheDecoder =
    let
        fromStringDecoder encodedActionState =
            case encodedActionState of
                "AddingFile" ->
                    Decode.succeed AddingFile

                "AddingFolder" ->
                    Decode.succeed AddingFolder

                "RemovingFile" ->
                    Decode.succeed RemovingFile

                "RemovingFolder" ->
                    Decode.succeed RemovingFolder

                _ ->
                    Decode.fail <| "Not a valid encoded action state: " ++ encodedActionState
    in
        Decode.string
            |> Decode.andThen fromStringDecoder


{-| A full bigbit ready for publication.
-}
type alias BigbitForPublication =
    { name : String
    , description : String
    , tags : List String
    }


{-| The metadata connected to the FS.
-}
type alias BigbitCreateDataFSMetadata =
    { activeFile : Maybe FS.Path
    , openFS : Bool
    , actionButtonState : Maybe FSActionButtonState
    , actionButtonInput : String
    }


{-| The metadata connected to every folder in the FS.
-}
type alias BigbitCreateDataFolderMetadata =
    { isExpanded : Bool
    }


{-| The metadata connected to every file in the FS.
-}
type alias BigbitCreateDataFileMetadata =
    { language : Editor.Language
    }


{-| The highlighted comments on bigbits are different than regular highlighted
comments (`Models/HighlightedComment`) because they also need to point to a
file.
-}
type alias BigbitHighlightedCommentForCreate =
    { comment : String
    , fileAndRange : Maybe FileAndRange
    }


{-| A file and a range, used in bigbit highlighted comments.
-}
type alias FileAndRange =
    { range : Maybe Range.Range
    , file : FS.Path
    }


{-| Creates an empty highlighted comment.
-}
emptyBigbitHighlightCommentForCreate : BigbitHighlightedCommentForCreate
emptyBigbitHighlightCommentForCreate =
    { comment = ""
    , fileAndRange = Nothing
    }


{-| BigbitHighlightedCommentForCreate `cacheEncoder`.
-}
bigbitHighlightedCommentForCreateCacheEncoder : BigbitHighlightedCommentForCreate -> Encode.Value
bigbitHighlightedCommentForCreateCacheEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "fileAndRange"
          , Util.justValueOrNull
                (\fileAndRange ->
                    Encode.object
                        [ ( "range", Util.justValueOrNull Range.rangeCacheEncoder fileAndRange.range )
                        , ( "file", Encode.string fileAndRange.file )
                        ]
                )
                hc.fileAndRange
          )
        ]


{-| BigbitHighlightedCommentForCreate `cacheDecoder`.
-}
bigbitHighlightedCommentForCreateCacheDecoder : Decode.Decoder BigbitHighlightedCommentForCreate
bigbitHighlightedCommentForCreateCacheDecoder =
    let
        decodeFileAndRange =
            Decode.maybe
                (decode FileAndRange
                    |> required "range" (Decode.maybe Range.rangeCacheDecoder)
                    |> required "file" Decode.string
                )
    in
        decode BigbitHighlightedCommentForCreate
            |> required "comment" Decode.string
            |> required "fileAndRange" decodeFileAndRange


{-| The data being stored for a bigbit being created.
-}
type alias BigbitCreateData =
    { name : String
    , description : String
    , tags : List String
    , tagInput : String
    , introduction : String
    , conclusion : String
    , fs : FS.FileStructure BigbitCreateDataFSMetadata BigbitCreateDataFolderMetadata BigbitCreateDataFileMetadata
    , highlightedComments : Array.Array BigbitHighlightedCommentForCreate
    }


{-| BigbitCreateData `cacheEncoder`.
-}
bigbitCreateDataCacheEncoder : BigbitCreateData -> Encode.Value
bigbitCreateDataCacheEncoder bigbitCreateData =
    let
        encodeFS =
            FS.encodeFS
                (\fsMetadata ->
                    Encode.object
                        [ ( "activeFile", Util.justValueOrNull Encode.string fsMetadata.activeFile )
                        , ( "openFS", Encode.bool fsMetadata.openFS )
                        , ( "actionButtonState", Util.justValueOrNull fsActionButtonStateCacheEncoder fsMetadata.actionButtonState )
                        , ( "actionButtonInput", Encode.string fsMetadata.actionButtonInput )
                        ]
                )
                (\folderMetadata ->
                    Encode.object
                        [ ( "isExpanded", Encode.bool folderMetadata.isExpanded ) ]
                )
                (\fileMetadata ->
                    Encode.object
                        [ ( "language", Editor.languageCacheEncoder fileMetadata.language ) ]
                )
    in
        Encode.object
            [ ( "name", Encode.string bigbitCreateData.name )
            , ( "description", Encode.string bigbitCreateData.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbitCreateData.tags )
            , ( "tagInput", Encode.string bigbitCreateData.tagInput )
            , ( "introduction", Encode.string bigbitCreateData.introduction )
            , ( "conclusion", Encode.string bigbitCreateData.conclusion )
            , ( "fs", encodeFS bigbitCreateData.fs )
            , ( "highlightedComments", Encode.array <| Array.map bigbitHighlightedCommentForCreateCacheEncoder bigbitCreateData.highlightedComments )
            ]


{-| BigbitCreateData `cacheDecoder`.
-}
bigbitCreateDataCacheDecoder : Decode.Decoder BigbitCreateData
bigbitCreateDataCacheDecoder =
    let
        decodeFS =
            FS.decodeFS
                (decode BigbitCreateDataFSMetadata
                    |> required "activeFile" (Decode.maybe Decode.string)
                    |> required "openFS" Decode.bool
                    |> required "actionButtonState" (Decode.maybe fsActionButtonStateCacheDecoder)
                    |> required "actionButtonInput" Decode.string
                )
                (decode BigbitCreateDataFolderMetadata
                    |> required "isExpanded" Decode.bool
                )
                (decode BigbitCreateDataFileMetadata
                    |> required "language" Editor.languageCacheDecoder
                )
    in
        decode BigbitCreateData
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "tagInput" Decode.string
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" decodeFS
            |> required "highlightedComments" (Decode.array bigbitHighlightedCommentForCreateCacheDecoder)


{-| Possible errors with input for creating a file.
-}
type InvalidFileName
    = FileHasInvalidCharacters
    | FileAlreadyExists
    | FileIsEmpty
    | FileHasDoubleSlash
    | FileEndsInSlash
    | FileHasInvalidExtension
    | FileLanguageIsAmbiguous (List Editor.Language)


{-| Possible errors with input for creating a folder.
-}
type InvalidFolderName
    = FolderHasInvalidCharacters
    | FolderAlreadyExists
    | FolderIsEmpty
    | FolderHasDoubleSlash


{-| Checks if the path has invalid characters.

NOTE: Only the following are valid characters: a-Z 1-9 - _ . /

NOTE: We restrict the characters because:
  - It'll keep it cleaner, I don't want funky ascii chars.
  - We'll need to encode them for the url params, prevent weird bugs.
-}
pathHasInvalidChars : FS.Path -> Bool
pathHasInvalidChars =
    String.toList
        >> List.all
            (\char ->
                Char.isDigit char
                    || Char.isUpper char
                    || Char.isLower char
                    || (List.member char [ '_', '-', '.', '/' ])
            )
        >> not


{-| Checks if the path has any double slashes ("//").
-}
pathHasDoubleSlash : FS.Path -> Bool
pathHasDoubleSlash =
    String.contains "//"


{-| Checks if the path is empty.
-}
pathIsEmpty : FS.Path -> Bool
pathIsEmpty =
    String.isEmpty


{-| Checks if the path ends in a slash.
-}
pathEndsInSlash : FS.Path -> Bool
pathEndsInSlash =
    String.endsWith "/"


{-| Checks that the folder path is valid.
-}
isValidAddFolderInput : FS.Path -> FS.FileStructure a b c -> Result InvalidFolderName ()
isValidAddFolderInput absolutePath fs =
    if pathIsEmpty absolutePath then
        Result.Err FolderIsEmpty
    else if pathHasDoubleSlash absolutePath then
        Result.Err FolderHasDoubleSlash
    else if pathHasInvalidChars absolutePath then
        Result.Err FolderHasInvalidCharacters
    else if FS.hasFolder absolutePath fs then
        Result.Err FolderAlreadyExists
    else
        Result.Ok ()


{-| Checks that a file path is valid and returns it's language.
-}
isValidAddFileInput : FS.Path -> FS.FileStructure a b c -> Result InvalidFileName Editor.Language
isValidAddFileInput absolutePath fs =
    if pathIsEmpty absolutePath then
        Result.Err FileIsEmpty
    else if pathHasDoubleSlash absolutePath then
        Result.Err FileHasDoubleSlash
    else if pathHasInvalidChars absolutePath then
        Result.Err FileHasInvalidCharacters
    else if pathEndsInSlash absolutePath then
        Result.Err FileEndsInSlash
    else if FS.hasFile absolutePath fs then
        Result.Err FileAlreadyExists
    else
        String.split "/" absolutePath
            |> Util.lastElem
            |> Maybe.map Editor.languagesFromFileName
            |> Maybe.withDefault []
            |> (\listOfLanguages ->
                    case listOfLanguages of
                        [] ->
                            Result.Err FileHasInvalidExtension

                        [ language ] ->
                            Result.Ok language

                        a ->
                            Result.Err <| FileLanguageIsAmbiguous a
               )



-- FS helpers below (refer to examples below to use row-polymorphism).


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


{-| Checks equality against the current state of `actionButtonState`.
-}
fsActionStateEquals : Maybe FSActionButtonState -> FS.FileStructure { a | actionButtonState : Maybe FSActionButtonState } b c -> Bool
fsActionStateEquals maybeActionState =
    FS.getFSMetadata >> .actionButtonState >> (==) maybeActionState


{-| Creates an empty folder.
-}
defaultEmptyFolder : FS.Folder BigbitCreateDataFolderMetadata BigbitCreateDataFileMetadata
defaultEmptyFolder =
    FS.emptyFolder { isExpanded = True }


{-| Clears the action button input.
-}
clearActionButtonInput : FS.FileStructure BigbitCreateDataFSMetadata b c -> FS.FileStructure BigbitCreateDataFSMetadata b c
clearActionButtonInput =
    FS.updateFSMetadata
        (\fsMetadata ->
            { fsMetadata
                | actionButtonInput = ""
            }
        )


{-| The current active path determined from the route.
-}
createPageCurrentActiveFile : Route.Route -> Maybe FS.Path
createPageCurrentActiveFile route =
    case route of
        Route.HomeComponentCreateBigbitCodeIntroduction maybePath ->
            maybePath

        Route.HomeComponentCreateBigbitCodeFrame _ maybePath ->
            maybePath

        Route.HomeComponentCreateBigbitCodeConclusion maybePath ->
            maybePath

        _ ->
            Nothing
