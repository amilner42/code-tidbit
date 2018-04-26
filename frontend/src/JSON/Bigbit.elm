module JSON.Bigbit exposing (..)

import Array
import DefaultServices.Util as Util
import JSON.FileStructure
import JSON.Language
import JSON.Range
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.Bigbit exposing (..)


{-| `Bigbit` encoder.
-}
encoder : Bigbit -> Encode.Value
encoder bigbit =
    let
        fsEncoder fs =
            JSON.FileStructure.encoder
                (\fsMetadata -> Encode.object [ ( "openFS", Encode.bool fsMetadata.openFS ) ])
                (\folderMetadata -> Encode.object [ ( "isExpanded", Encode.bool folderMetadata.isExpanded ) ])
                (\fileMetadata -> Encode.object [ ( "language", JSON.Language.encoder fileMetadata.language ) ])
                fs
    in
    Encode.object
        [ ( "name", Encode.string bigbit.name )
        , ( "description", Encode.string bigbit.description )
        , ( "tags", Encode.list <| List.map Encode.string bigbit.tags )
        , ( "fs", fsEncoder bigbit.fs )
        , ( "highlightedComments", Encode.array <| Array.map highlightedCommentEncoder bigbit.highlightedComments )
        , ( "author", Encode.string bigbit.author )
        , ( "authorEmail", Encode.string bigbit.authorEmail )
        , ( "id", Encode.string bigbit.id )
        , ( "createdAt", Util.dateEncoder bigbit.createdAt )
        , ( "lastModified", Util.dateEncoder bigbit.lastModified )
        , ( "languages", Encode.list <| List.map JSON.Language.encoder bigbit.languages )
        , ( "likes", Encode.int bigbit.likes )
        ]


{-| `Bigbit` decoder.
-}
decoder : Decode.Decoder Bigbit
decoder =
    let
        fsDecoder =
            JSON.FileStructure.decoder
                (decode (\isOpen -> { openFS = isOpen })
                    |> optional "openFS" Decode.bool True
                )
                (decode (\isExpanded -> { isExpanded = isExpanded })
                    |> optional "isExpanded" Decode.bool True
                )
                (decode FileMetadata
                    |> required "language" JSON.Language.decoder
                )
    in
    decode Bigbit
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "fs" fsDecoder
        |> required "highlightedComments" (Decode.array highlightedCommentDecoder)
        |> required "author" Decode.string
        |> required "authorEmail" Decode.string
        |> required "id" Decode.string
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder
        |> required "languages" (Decode.list JSON.Language.decoder)
        -- Optional for backwards compatibility.
        |> optional "likes" Decode.int 0


{-| `HighlightedComment` encoder.
-}
highlightedCommentEncoder : HighlightedComment -> Encode.Value
highlightedCommentEncoder hc =
    Encode.object
        [ ( "comment", Encode.string hc.comment )
        , ( "range", JSON.Range.encoder hc.range )
        , ( "file", Encode.string hc.file )
        ]


{-| `HighlightedComment` decoder.
-}
highlightedCommentDecoder : Decode.Decoder HighlightedComment
highlightedCommentDecoder =
    decode HighlightedComment
        |> required "comment" Decode.string
        |> required "range" JSON.Range.decoder
        |> required "file" Decode.string
