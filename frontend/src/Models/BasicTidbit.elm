module Models.BasicTidbit exposing (..)

import Array
import Autocomplete as AC
import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.Editor exposing (Language, languageCacheDecoder, languageCacheEncoder)
import Models.HighlightedComment exposing (MaybeHighlightedComment, maybeHighlightedCommentCacheEncoder, maybeHighlightedCommentCacheDecoder)
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
    , highlightedComments : Array.Array MaybeHighlightedComment
    , introduction : String
    , conclusion : String
    , currentCommentTab : CommentTab
    }


{-| The comment tab box
-}
type CommentTab
    = Introduction
    | Frame Int
    | Conclusion


{-| The commentTab `cacheEncoder`.
-}
commentTabCacheEncoder : CommentTab -> Encode.Value
commentTabCacheEncoder commentTab =
    Encode.string <| toString commentTab


{-| The commentTab `cacheDecoder`.
-}
commentTabCacheDecoder : Decode.Decoder CommentTab
commentTabCacheDecoder =
    let
        fromStringDecoder : String -> Decode.Decoder CommentTab
        fromStringDecoder encodedCommentTab =
            case encodedCommentTab of
                "Introduction" ->
                    Decode.succeed Introduction

                "Conclusion" ->
                    Decode.succeed Conclusion

                _ ->
                    if String.startsWith "Frame " encodedCommentTab then
                        let
                            frameString =
                                String.dropLeft 6 encodedCommentTab

                            frameInteger =
                                String.toInt frameString
                        in
                            case frameInteger of
                                Ok int ->
                                    Decode.succeed <| Frame int

                                Err err ->
                                    Decode.fail err
                    else
                        Decode.fail <| encodedCommentTab ++ " is not a valid encoded comment tab"
    in
        Decode.andThen fromStringDecoder Decode.string


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
          , Encode.array <|
                Array.map
                    maybeHighlightedCommentCacheEncoder
                    basicTidbitCreateData.highlightedComments
          )
        , ( "introduction", Encode.string basicTidbitCreateData.introduction )
        , ( "conclusion", Encode.string basicTidbitCreateData.conclusion )
        , ( "currentCommentTab"
          , commentTabCacheEncoder basicTidbitCreateData.currentCommentTab
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
            (Decode.array maybeHighlightedCommentCacheDecoder)
        |> required "introduction" Decode.string
        |> required "conclusion" Decode.string
        |> required "currentCommentTab" commentTabCacheDecoder
