module JSON.Bigbit exposing (..)

import Array
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Language
import JSON.FileStructure
import JSON.Range
import Models.Bigbit exposing (..)


{-| `Bigbit` encoder.
-}
encoder : Bigbit -> Encode.Value
encoder bigbit =
    let
        fsEncoder fs =
            JSON.FileStructure.encoder
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
                        [ ( "language", JSON.Language.encoder fileMetadata.language ) ]
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
        fsDecoder =
            JSON.FileStructure.decoder
                (decode (\isOpen -> { openFS = isOpen })
                    |> optional "openFS" Decode.bool False
                )
                (decode (\isExpanded -> { isExpanded = isExpanded })
                    |> optional "isExpanded" Decode.bool True
                )
                (decode BigbitCreateDataFileMetadata
                    |> required "language" JSON.Language.decoder
                )
    in
        decode Bigbit
            |> required "name" Decode.string
            |> required "description" Decode.string
            |> required "tags" (Decode.list Decode.string)
            |> required "introduction" Decode.string
            |> required "conclusion" Decode.string
            |> required "fs" fsDecoder
            |> required "highlightedComments" (Decode.array publicationHighlightedCommentDecoder)
            |> required "author" Decode.string
            |> required "id" Decode.string
            |> required "createdAt" Util.dateDecoder
            |> required "lastModified" Util.dateDecoder


{-| `BigbitHighlightedCommentForPublication` encoder.
-}
publicationHighlightedCommentEncoder : BigbitHighlightedCommentForPublication -> Encode.Value
publicationHighlightedCommentEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "range", JSON.Range.encoder hc.range )
        , ( "file", Encode.string hc.file )
        ]


{-| `BigbitHighlightedCommentForPublication` decoder.
-}
publicationHighlightedCommentDecoder : Decode.Decoder BigbitHighlightedCommentForPublication
publicationHighlightedCommentDecoder =
    decode BigbitHighlightedCommentForPublication
        |> required "comment" Decode.string
        |> required "range" JSON.Range.decoder
        |> required "file" Decode.string
