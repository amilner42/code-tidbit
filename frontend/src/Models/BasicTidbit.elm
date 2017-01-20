module Models.BasicTidbit exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)
import Models.HighlightedComment exposing (MaybeHighlightedComment, HighlightedComment, maybeHighlightedCommentCacheEncoder, maybeHighlightedCommentCacheDecoder, highlightedCommentEncoder, highlightedCommentDecoder)
import Models.Range as Range


{-| A full BasicTidbit ready for publication.
-}
type alias BasicTidbit =
    { language : Language
    , name : String
    , description : String
    , tags : List String
    , code : String
    , introduction : String
    , conclusion : String
    , highlightedComments : Array.Array HighlightedComment
    }


{-| The data for a basic tidbit being created.
-}
type alias BasicTidbitCreateData =
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


{-| BasicTidbit `encoder`.
-}
basicTidbitEncoder : BasicTidbit -> Encode.Value
basicTidbitEncoder basicTidbit =
    Encode.object
        [ ( "language", languageCacheEncoder basicTidbit.language )
        , ( "name", Encode.string basicTidbit.name )
        , ( "description", Encode.string basicTidbit.description )
        , ( "tags", Encode.list <| List.map Encode.string basicTidbit.tags )
        , ( "code", Encode.string basicTidbit.code )
        , ( "introduction", Encode.string basicTidbit.introduction )
        , ( "conclusion", Encode.string basicTidbit.conclusion )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    highlightedCommentEncoder
                    basicTidbit.highlightedComments
          )
        ]


{-| BasicTidbit `decoder`.
-}
basicTidbitDecoder : Decode.Decoder BasicTidbit
basicTidbitDecoder =
    decode BasicTidbit
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array highlightedCommentDecoder)


{-| BasicTidbitCreateData `cacheEncoder`.
-}
createDataCacheEncoder : BasicTidbitCreateData -> Encode.Value
createDataCacheEncoder basicTidbitCreateData =
    Encode.object
        [ ( "language"
          , Util.justValueOrNull
                languageCacheEncoder
                basicTidbitCreateData.language
          )
        , ( "languageQueryACState", Encode.null )
        , ( "languageListHowManyToShow", Encode.int basicTidbitCreateData.languageListHowManyToShow )
        , ( "languageQuery", Encode.string basicTidbitCreateData.languageQuery )
        , ( "name", Encode.string basicTidbitCreateData.name )
        , ( "description", Encode.string basicTidbitCreateData.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string basicTidbitCreateData.tags
          )
        , ( "tagInput", Encode.string basicTidbitCreateData.tagInput )
        , ( "code", Encode.string basicTidbitCreateData.code )
        , ( "highlightedComments"
          , Encode.array <|
                Array.map
                    maybeHighlightedCommentCacheEncoder
                    basicTidbitCreateData.highlightedComments
          )
        , ( "introduction", Encode.string basicTidbitCreateData.introduction )
        , ( "conclusion", Encode.string basicTidbitCreateData.conclusion )
        ]


{-| BasicTidbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder BasicTidbitCreateData
createDataCacheDecoder =
    decode BasicTidbitCreateData
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
