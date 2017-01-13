module Models.BasicTidbit exposing (..)

import Autocomplete as AC
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)
import Models.HighlightedComment as HighlightedComment
import Models.Range as Range


{-| The data for a basic tidbit being created.
-}
type alias BasicTidbitCreateData =
    { language : Maybe Language
    , languageQueryACState : AC.State
    , languageQuery : String
    , name : String
    , description : String
    , tags : List String
    , tagInput : String
    , code : String
    , highlightedComments : List HighlightedComment.HighlightedComment
    , currentComment : String
    , currentRange : Maybe Range.Range
    }


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
        , ( "languageQuery", Encode.string basicTidbitCreateData.languageQuery )
        , ( "name", Encode.string basicTidbitCreateData.name )
        , ( "description", Encode.string basicTidbitCreateData.description )
        , ( "tags"
          , Encode.list <| List.map Encode.string basicTidbitCreateData.tags
          )
        , ( "tagInput", Encode.string basicTidbitCreateData.tagInput )
        , ( "code", Encode.string basicTidbitCreateData.code )
        , ( "highlightedComments"
          , Encode.list <|
                List.map
                    HighlightedComment.highlightedCommentCacheEncoder
                    basicTidbitCreateData.highlightedComments
          )
        , ( "currentComment"
          , Encode.string basicTidbitCreateData.currentComment
          )
        , ( "currentRange"
          , Util.justValueOrNull
                Range.rangeCacheEncoder
                basicTidbitCreateData.currentRange
          )
        ]


{-| BasicTidbitCreateData `cacheDecoder`.
-}
createDataCacheDecoder : Decode.Decoder BasicTidbitCreateData
createDataCacheDecoder =
    decode BasicTidbitCreateData
        |> required "language" (Decode.maybe languageCacheDecoder)
        |> required "languageQueryACState" (Decode.succeed AC.empty)
        |> required "languageQuery" Decode.string
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "tagInput" Decode.string
        |> required "code" Decode.string
        |> required
            "highlightedComments"
            (Decode.list HighlightedComment.highlightedCommentCacheDecoder)
        |> required "currentComment" Decode.string
        |> required "currentRange" (Decode.maybe Range.rangeCacheDecoder)
