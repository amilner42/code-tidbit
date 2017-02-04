module Models.Bigbit exposing (..)

import Char
import DefaultServices.Util as Util
import Dict
import Elements.Editor as Editor
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.HighlightedComment as HighlightedComment
import Models.FileStructure as FS


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
    {}


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
                (\fileMetadata -> Encode.object [])
    in
        Encode.object
            [ ( "name", Encode.string bigbitCreateData.name )
            , ( "description", Encode.string bigbitCreateData.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbitCreateData.tags )
            , ( "tagInput", Encode.string bigbitCreateData.tagInput )
            , ( "introduction", Encode.string bigbitCreateData.introduction )
            , ( "conclusion", Encode.string bigbitCreateData.conclusion )
            , ( "fs", encodeFS bigbitCreateData.fs )
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
                (decode BigbitCreateDataFileMetadata)
    in
        decode BigbitCreateData
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "tagInput" Decode.string
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" decodeFS


{-| Checks that all the characters are any combination of: a-Z 1-9 - _ . /

NOTE: We restrict the characters because:
  - It'll keep it cleaner, I don't want funky ascii chars.
  - We'll need to encode them for the url params, prevent weird bugs.
-}
validPathChars : FS.Path -> Bool
validPathChars =
    String.toList
        >> List.all
            (\char ->
                Char.isDigit char
                    || Char.isUpper char
                    || Char.isLower char
                    || (List.member char [ '_', '-', '.', '/' ])
            )


{-| Checks that the path is valid.
-}
validPath : FS.Path -> Bool
validPath absolutePath =
    validPathChars absolutePath
        && (not <| String.contains "//" absolutePath)
        && (String.length absolutePath /= 0)


{-| Checks that the folder path is valid.
-}
isValidAddFolderInput : FS.Path -> FS.FileStructure a b c -> Bool
isValidAddFolderInput absolutePath fs =
    validPath absolutePath && (not <| FS.hasFolder absolutePath fs)


{-| Checks that the file path is valid.
-}
isValidAddFileInput : FS.Path -> FS.FileStructure a b c -> Bool
isValidAddFileInput absolutePath =
    getLanguagesForFileInput absolutePath >> List.length >> (/=) 0


{-| Checks that a file path is valid and returns the possible languages of the
file.

NOTE: For the most part that'll be one language, but due to ambiguities like
`.sql` it can return more than one. An invalid file name of any sort will
have an empty list returned.
-}
getLanguagesForFileInput : FS.Path -> FS.FileStructure a b c -> List Editor.Language
getLanguagesForFileInput absolutePath fs =
    if FS.hasFile absolutePath fs || (not <| validPath absolutePath) || (String.endsWith "/" absolutePath) then
        []
    else
        String.split "/" absolutePath
            |> Util.lastElem
            |> Maybe.map Editor.languagesFromFileName
            |> Maybe.withDefault []



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
