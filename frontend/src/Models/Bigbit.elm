module Models.Bigbit exposing (..)

import DefaultServices.Util as Util
import Dict
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
