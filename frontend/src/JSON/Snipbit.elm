module JSON.Snipbit exposing (..)

import Array
import DefaultServices.Util as Util
import JSON.Language
import JSON.Range
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.Snipbit exposing (..)


{-| `Snipbit` encoder.
-}
encoder : Snipbit -> Encode.Value
encoder snipbit =
    Encode.object
        [ ( "language", JSON.Language.encoder snipbit.language )
        , ( "name", Encode.string snipbit.name )
        , ( "description", Encode.string snipbit.description )
        , ( "tags", Encode.list <| List.map Encode.string snipbit.tags )
        , ( "code", Encode.string snipbit.code )
        , ( "highlightedComments", Encode.array <| Array.map hcEncoder snipbit.highlightedComments )
        , ( "id", Encode.string snipbit.id )
        , ( "author", Encode.string snipbit.author )
        , ( "authorEmail", Encode.string snipbit.authorEmail )
        , ( "createdAt", Util.dateEncoder snipbit.createdAt )
        , ( "lastModified", Util.dateEncoder snipbit.lastModified )
        , ( "likes", Encode.int snipbit.likes )
        ]


{-| `Snipbit` decoder.
-}
decoder : Decode.Decoder Snipbit
decoder =
    decode Snipbit
        |> required "id" Decode.string
        |> required "language" JSON.Language.decoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "highlightedComments" (Decode.array hcDecoder)
        |> required "author" Decode.string
        |> required "authorEmail" Decode.string
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder
        -- Optional for backwards compatibility.
        |> optional "likes" Decode.int 0


{-| `HighlightedComment` encoder.
-}
hcEncoder : HighlightedComment -> Encode.Value
hcEncoder hc =
    Encode.object
        [ ( "range", JSON.Range.encoder hc.range )
        , ( "comment", Encode.string hc.comment )
        ]


{-| `HighlightedComment` decoder.
-}
hcDecoder : Decode.Decoder HighlightedComment
hcDecoder =
    decode HighlightedComment
        |> required "range" JSON.Range.decoder
        |> required "comment" Decode.string


{-| `MaybeHighlightedComment` encoder.
-}
maybeHCEncoder : MaybeHighlightedComment -> Encode.Value
maybeHCEncoder maybeHighlightedComment =
    Encode.object
        [ ( "range", Util.justValueOrNull JSON.Range.encoder maybeHighlightedComment.range )
        , ( "comment", Util.justValueOrNull Encode.string maybeHighlightedComment.comment )
        ]


{-| `MaybeHighlightedComment` decoder.
-}
maybeHCDecoder : Decode.Decoder MaybeHighlightedComment
maybeHCDecoder =
    decode MaybeHighlightedComment
        |> required "range" (Decode.maybe JSON.Range.decoder)
        |> required "comment" (Decode.maybe Decode.string)
