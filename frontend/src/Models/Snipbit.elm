module Models.Snipbit exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)
import Models.HighlightedComment exposing (MaybeHighlightedComment, HighlightedComment, maybeHighlightedCommentCacheEncoder, maybeHighlightedCommentCacheDecoder, highlightedCommentEncoder, highlightedCommentDecoder)
import Models.Range as Range


{-| A full Snipbit ready for publication.
-}
type alias Snipbit =
    { language : Language
    , name : String
    , description : String
    , tags : List String
    , code : String
    , introduction : String
    , conclusion : String
    , highlightedComments : Array.Array HighlightedComment
    }


{-| The data for a snipbit being created.
-}
type alias SnipbitCreateData =
    { language : Maybe Language
    , languageQueryACState : AC.State
    , languageListHowManyToShow : Int
    , languageQuery : String
    , name : String
    , description : String
    , tags : List String
    , tagInput : String
    , code : String
    , highlightedComments : Array.Array MaybeHighlightedComment
    , introduction : String
    , conclusion : String
    }


{-| Identical to the encoder, but used to follow naming conventions.
-}
snipbitCacheEncoder =
    snipbitEncoder


{-| Identical to the decoder, but used to follow naming conventions.
-}
snipbitCacheDecoder =
    snipbitDecoder


{-| Snipbit `encoder`.
-}
snipbitEncoder : Snipbit -> Encode.Value
snipbitEncoder snipbit =
    Encode.object
        [ ( "language", languageCacheEncoder snipbit.language )
        , ( "name", Encode.string snipbit.name )
        , ( "description", Encode.string snipbit.description )
        , ( "tags", Encode.list <| List.map Encode.string snipbit.tags )
        , ( "code", Encode.string snipbit.code )
        , ( "introduction", Encode.string snipbit.introduction )
        , ( "conclusion", Encode.string snipbit.conclusion )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    highlightedCommentEncoder
                    snipbit.highlightedComments
          )
        ]


{-| Snipbit `decoder`.
-}
snipbitDecoder : Decode.Decoder Snipbit
snipbitDecoder =
    decode Snipbit
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array highlightedCommentDecoder)


{-| SnipbitCreateData `cacheEncoder`.
-}
createDataCacheEncoder : SnipbitCreateData -> Encode.Value
createDataCacheEncoder snipbitCreateData =
    Encode.object
        [ ( "language"
          , Util.justValueOrNull
                languageCacheEncoder
                snipbitCreateData.language
          )
        , ( "languageQueryACState", Encode.null )
        , ( "languageListHowManyToShow", Encode.int snipbitCreateData.languageListHowManyToShow )
        , ( "languageQuery", Encode.string snipbitCreateData.languageQuery )
        , ( "name", Encode.string snipbitCreateData.name )
        , ( "description", Encode.string snipbitCreateData.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string snipbitCreateData.tags
          )
        , ( "tagInput", Encode.string snipbitCreateData.tagInput )
        , ( "code", Encode.string snipbitCreateData.code )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    maybeHighlightedCommentCacheEncoder
                    snipbitCreateData.highlightedComments
          )
        , ( "introduction", Encode.string snipbitCreateData.introduction )
        , ( "conclusion", Encode.string snipbitCreateData.conclusion )
        ]


{-| SnipbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder SnipbitCreateData
createDataCacheDecoder =
    decode SnipbitCreateData
        |> required "language" (Decode.maybe languageCacheDecoder)
        |> required "languageQueryACState" (Decode.succeed AC.empty)
        |> required "languageListHowManyToShow" (Decode.int)
        |> required "languageQuery" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
        |> required "code" Decode.string
        |> required
            "highlightedComments"
            (Decode.array maybeHighlightedCommentCacheDecoder)
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
