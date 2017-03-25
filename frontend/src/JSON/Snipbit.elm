module JSON.Snipbit exposing (..)

import Array
import DefaultServices.Util as Util
import JSON.HighlightedComment
import JSON.Language
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
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
        , ( "introduction", Encode.string snipbit.introduction )
        , ( "conclusion", Encode.string snipbit.conclusion )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    JSON.HighlightedComment.encoder
                    snipbit.highlightedComments
          )
        , ( "id", Encode.string snipbit.id )
        , ( "author", Encode.string snipbit.author )
        , ( "createdAt", Util.dateEncoder snipbit.createdAt )
        , ( "lastModified", Util.dateEncoder snipbit.lastModified )
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
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array JSON.HighlightedComment.decoder)
        |> required "author" Decode.string
        |> required "createdAt" Util.dateDecoder
        |> required "lastModified" Util.dateDecoder
