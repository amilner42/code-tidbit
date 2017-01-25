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


{-| A snipbit as seen in the db.
-}
type alias Snipbit =
    { id : String
    , language : Language
    , name : String
    , description : String
    , tags : List String
    , code : String
    , introduction : String
    , conclusion : String
    , highlightedComments : Array.Array HighlightedComment
    , author : String
    }


{-| A full SnipbitForPublication ready for publication.
-}
type alias SnipbitForPublication =
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


{-| For DRY code to create encoders for `Snipbit` and `SnipbitForPublication`.
-}
createSnippetEncoder model extraFields =
    Encode.object <|
        List.concat
            [ [ ( "language", languageCacheEncoder model.language )
              , ( "name", Encode.string model.name )
              , ( "description", Encode.string model.description )
              , ( "tags", Encode.list <| List.map Encode.string model.tags )
              , ( "code", Encode.string model.code )
              , ( "introduction", Encode.string model.introduction )
              , ( "conclusion", Encode.string model.conclusion )
              , ( "highlightedComments"
                , Encode.array <|
                    Array.map
                        highlightedCommentEncoder
                        model.highlightedComments
                )
              ]
            , extraFields
            ]


{-| Snipbit `cacheDecoder`.
-}
snipbitCacheDecoder : Decode.Decoder Snipbit
snipbitCacheDecoder =
    snipbitDecoder


{-| Snipbit `cacheEncoder`.
-}
snipbitCacheEncoder : Snipbit -> Encode.Value
snipbitCacheEncoder =
    snipbitEncoder


{-| Snipbit `encoder`.
-}
snipbitEncoder : Snipbit -> Encode.Value
snipbitEncoder snipbit =
    createSnippetEncoder
        snipbit
        [ ( "id", Encode.string snipbit.id )
        , ( "author", Encode.string snipbit.author )
        ]


{-| Snipbit `decoder`.
-}
snipbitDecoder : Decode.Decoder Snipbit
snipbitDecoder =
    decode Snipbit
        |> required "id" Decode.string
        |> required "language" languageCacheDecoder
        |> required "name" Decode.string
        |> required "description" Decode.string
        |> required "tags" (Decode.list Decode.string)
        |> required "code" Decode.string
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "highlightedComments" (Decode.array highlightedCommentDecoder)
        |> required "author" Decode.string


{-| Identical to the encoder, but used to follow naming conventions.
-}
snipbitForPublicationCacheEncoder =
    snipbitForPublicationEncoder


{-| Identical to the decoder, but used to follow naming conventions.
-}
snipbitForPublicationCacheDecoder =
    snipbitForSymbolDecoder


{-| SnipbitForPublication `encoder`.
-}
snipbitForPublicationEncoder : SnipbitForPublication -> Encode.Value
snipbitForPublicationEncoder snipbitForPublication =
    createSnippetEncoder snipbitForPublication []


{-| SnipbitForPublication `decoder`.
-}
snipbitForSymbolDecoder : Decode.Decoder SnipbitForPublication
snipbitForSymbolDecoder =
    decode SnipbitForPublication
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
