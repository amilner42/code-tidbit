module JSON.Bigbit exposing (..)

import Array
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Range as JSONRange
import Models.Bigbit exposing (..)
import Models.Range as Range
import Elements.FileStructure as FS
import Elements.Editor as Editor


{-| `Bigbit` encoder.
-}
encoder : Bigbit -> Encode.Value
encoder bigbit =
    let
        encodeFS fs =
            FS.encodeFS
                (\fsMetadata ->
                    Encode.object
                        [ ( "openFS", Encode.bool fsMetadata.openFS ) ]
                )
                (\folderMetadata ->
                    Encode.object
                        [ ( "isExpanded", Encode.bool folderMetadata.isExpanded ) ]
                )
                (\fileMetadata ->
                    Encode.object
                        [ ( "language", Editor.languageCacheEncoder fileMetadata.language ) ]
                )
                fs
    in
        Encode.object
            [ ( "name", Encode.string bigbit.name )
            , ( "description", Encode.string bigbit.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbit.tags )
            , ( "introduction", Encode.string bigbit.introduction )
            , ( "conclusion", Encode.string bigbit.conclusion )
            , ( "fs", encodeFS bigbit.fs )
            , ( "highlightedComments"
              , Encode.array <|
                    Array.map
                        publicationHighlightedCommentEncoder
                        bigbit.highlightedComments
              )
            , ( "author", Encode.string bigbit.author )
            , ( "id", Encode.string bigbit.id )
            , ( "createdAt", Util.dateEncoder bigbit.createdAt )
            , ( "lastModified", Util.dateEncoder bigbit.lastModified )
            ]


{-| `Bigbit` decoder.
-}
decoder : Decode.Decoder Bigbit
decoder =
    let
        decodeFS =
            FS.decodeFS
                (decode (\isOpen -> { openFS = isOpen })
                    |> optional "openFS" Decode.bool False
                )
                (decode (\isExpanded -> { isExpanded = isExpanded })
                    |> optional "isExpanded" Decode.bool True
                )
                (decode BigbitCreateDataFileMetadata
                    |> required "language" Editor.languageCacheDecoder
                )
    in
        decode Bigbit
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" decodeFS
            |> required "highlightedComments" (Decode.array publicationHighlightedCommentDecoder)
            |> required "author" Decode.string
            |> required "id" Decode.string
            |> required "createdAt" Util.dateDecoder
            |> required "lastModified" Util.dateDecoder


{-| `FSActionButtonState` encoder.
-}
fsActionButtonStateEncoder : FSActionButtonState -> Encode.Value
fsActionButtonStateEncoder =
    toString >> Encode.string


{-| `FSActionButtonState` decoder.
-}
fsActionButtonStateDecoder : Decode.Decoder FSActionButtonState
fsActionButtonStateDecoder =
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


{-| `BigbitForPublication` encoder.
-}
publicationEncoder : BigbitForPublication -> Encode.Value
publicationEncoder bigbit =
    let
        encodeFS fs =
            FS.encodeFS
                (always <| Encode.object [])
                (always <| Encode.object [])
                (\fileMetadata ->
                    Encode.object
                        [ ( "language", Editor.languageCacheEncoder fileMetadata.language ) ]
                )
                fs
    in
        Encode.object
            [ ( "name", Encode.string bigbit.name )
            , ( "description", Encode.string bigbit.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbit.tags )
            , ( "introduction", Encode.string bigbit.introduction )
            , ( "conclusion", Encode.string bigbit.conclusion )
            , ( "fs", encodeFS bigbit.fs )
            , ( "highlightedComments"
              , Encode.list <|
                    List.map
                        publicationHighlightedCommentEncoder
                        bigbit.highlightedComments
              )
            ]


{-| `BigbitHighlightedCommentForPublication` encoder.
-}
publicationHighlightedCommentEncoder : BigbitHighlightedCommentForPublication -> Encode.Value
publicationHighlightedCommentEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "range", JSONRange.encoder hc.range )
        , ( "file", Encode.string hc.file )
        ]


{-| `BigbitHighlightedCommentForPublication` decoder.
-}
publicationHighlightedCommentDecoder : Decode.Decoder BigbitHighlightedCommentForPublication
publicationHighlightedCommentDecoder =
    decode BigbitHighlightedCommentForPublication
        |> required "comment" Decode.string
        |> required "range" JSONRange.decoder
        |> required "file" Decode.string


{-| `BigbitHighlightedCommentForCreate` encoder.
-}
createHighlightedCommentEncoder : BigbitHighlightedCommentForCreate -> Encode.Value
createHighlightedCommentEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "fileAndRange"
          , Util.justValueOrNull
                (\fileAndRange ->
                    Encode.object
                        [ ( "range", Util.justValueOrNull JSONRange.encoder fileAndRange.range )
                        , ( "file", Encode.string fileAndRange.file )
                        ]
                )
                hc.fileAndRange
          )
        ]


{-| `BigbitHighlightedCommentForCreate` decoder.
-}
createHighlightedCommentDecoder : Decode.Decoder BigbitHighlightedCommentForCreate
createHighlightedCommentDecoder =
    let
        decodeFileAndRange =
            Decode.maybe
                (decode FileAndRange
                    |> required "range" (Decode.maybe JSONRange.decoder)
                    |> required "file" Decode.string
                )
    in
        decode BigbitHighlightedCommentForCreate
            |> required "comment" Decode.string
            |> required "fileAndRange" decodeFileAndRange


{-| `BigbitCreateData` encoder.
-}
createDataEncoder : BigbitCreateData -> Encode.Value
createDataEncoder bigbitCreateData =
    let
        encodeFS =
            FS.encodeFS
                (\fsMetadata ->
                    Encode.object
                        [ ( "activeFile", Util.justValueOrNull Encode.string fsMetadata.activeFile )
                        , ( "openFS", Encode.bool fsMetadata.openFS )
                        , ( "actionButtonState", Util.justValueOrNull fsActionButtonStateEncoder fsMetadata.actionButtonState )
                        , ( "actionButtonInput", Encode.string fsMetadata.actionButtonInput )
                        , ( "actionButtonSubmitConfirmed", Encode.bool fsMetadata.actionButtonSubmitConfirmed )
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
            , ( "highlightedComments", Encode.array <| Array.map createHighlightedCommentEncoder bigbitCreateData.highlightedComments )
            , ( "previewMarkdown", Encode.bool bigbitCreateData.previewMarkdown )
            ]


{-| `BigbitCreateData` decoder.
-}
createDataDecoder : Decode.Decoder BigbitCreateData
createDataDecoder =
    let
        decodeFS =
            FS.decodeFS
                (decode BigbitCreateDataFSMetadata
                    |> required "activeFile" (Decode.maybe Decode.string)
                    |> required "openFS" Decode.bool
                    |> required "actionButtonState" (Decode.maybe fsActionButtonStateDecoder)
                    |> required "actionButtonInput" Decode.string
                    |> required "actionButtonSubmitConfirmed" Decode.bool
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
            |> required "highlightedComments" (Decode.array createHighlightedCommentDecoder)
            |> required "previewMarkdown" Decode.bool
