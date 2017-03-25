module Pages.CreateBigbit.JSON exposing (..)

import Array
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Bigbit exposing (publicationHighlightedCommentEncoder)
import JSON.Range
import JSON.Language
import JSON.FileStructure
import Models.Range as Range
import Models.Bigbit exposing (BigbitCreateDataFolderMetadata, BigbitCreateDataFileMetadata)
import Pages.CreateBigbit.Model exposing (..)


{-| `CreateBigbitModel` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    let
        fsEncoder =
            JSON.FileStructure.encoder
                (\fsMetadata ->
                    Encode.object
                        [ ( "activeFile"
                          , Util.justValueOrNull
                                Encode.string
                                fsMetadata.activeFile
                          )
                        , ( "openFS", Encode.bool fsMetadata.openFS )
                        , ( "actionButtonState"
                          , Util.justValueOrNull
                                fsActionButtonStateEncoder
                                fsMetadata.actionButtonState
                          )
                        , ( "actionButtonInput"
                          , Encode.string fsMetadata.actionButtonInput
                          )
                        , ( "actionButtonSubmitConfirmed"
                          , Encode.bool fsMetadata.actionButtonSubmitConfirmed
                          )
                        ]
                )
                (\folderMetadata ->
                    Encode.object
                        [ ( "isExpanded"
                          , Encode.bool folderMetadata.isExpanded
                          )
                        ]
                )
                (\fileMetadata ->
                    Encode.object
                        [ ( "language"
                          , JSON.Language.encoder fileMetadata.language
                          )
                        ]
                )
    in
        Encode.object
            [ ( "name", Encode.string model.name )
            , ( "description", Encode.string model.description )
            , ( "tags", Encode.list <| List.map Encode.string model.tags )
            , ( "tagInput", Encode.string model.tagInput )
            , ( "introduction", Encode.string model.introduction )
            , ( "conclusion", Encode.string model.conclusion )
            , ( "fs", fsEncoder model.fs )
            , ( "highlightedComments"
              , Encode.array <|
                    Array.map
                        createHighlightedCommentEncoder
                        model.highlightedComments
              )
            , ( "previewMarkdown", Encode.bool model.previewMarkdown )
            ]


{-| `CreateBigbitModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    let
        fsDecoder =
            JSON.FileStructure.decoder
                (decode BigbitCreateDataFSMetadata
                    |> required "activeFile" (Decode.maybe Decode.string)
                    |> required "openFS" Decode.bool
                    |> required "actionButtonState"
                        (Decode.maybe fsActionButtonStateDecoder)
                    |> required "actionButtonInput" Decode.string
                    |> required "actionButtonSubmitConfirmed" Decode.bool
                )
                (decode BigbitCreateDataFolderMetadata
                    |> required "isExpanded" Decode.bool
                )
                (decode BigbitCreateDataFileMetadata
                    |> required "language" JSON.Language.decoder
                )
    in
        decode Model
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "tagInput" Decode.string
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" fsDecoder
            |> required "highlightedComments"
                (Decode.array createHighlightedCommentDecoder)
            |> required "previewMarkdown" Decode.bool


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
                    Decode.fail <|
                        "Not a valid encoded action state: "
                            ++ encodedActionState
    in
        Decode.string
            |> Decode.andThen fromStringDecoder


{-| `BigbitForPublication` encoder.
-}
publicationEncoder : BigbitForPublication -> Encode.Value
publicationEncoder bigbit =
    let
        fsEncoder fs =
            JSON.FileStructure.encoder
                (always <| Encode.object [])
                (always <| Encode.object [])
                (\fileMetadata ->
                    Encode.object
                        [ ( "language"
                          , JSON.Language.encoder fileMetadata.language
                          )
                        ]
                )
                fs
    in
        Encode.object
            [ ( "name", Encode.string bigbit.name )
            , ( "description", Encode.string bigbit.description )
            , ( "tags", Encode.list <| List.map Encode.string bigbit.tags )
            , ( "introduction", Encode.string bigbit.introduction )
            , ( "conclusion", Encode.string bigbit.conclusion )
            , ( "fs", fsEncoder bigbit.fs )
            , ( "highlightedComments"
              , Encode.list <|
                    List.map
                        publicationHighlightedCommentEncoder
                        bigbit.highlightedComments
              )
            ]


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
                        [ ( "range"
                          , Util.justValueOrNull
                                JSON.Range.encoder
                                fileAndRange.range
                          )
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
                    |> required "range" (Decode.maybe JSON.Range.decoder)
                    |> required "file" Decode.string
                )
    in
        decode BigbitHighlightedCommentForCreate
            |> required "comment" Decode.string
            |> required "fileAndRange" decodeFileAndRange